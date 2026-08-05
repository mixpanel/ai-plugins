#!/usr/bin/env python3
"""Deterministic helpers for the manage-boards cleanup/audit workflow.

Centralizes the two routines the agent would otherwise re-derive on every run:
title normalization + duplicate detection, and recency arithmetic.

Usage (from the cleanup command):
    from dashboard_utils import normalize_title, is_probable_duplicate, days_since

    norm = normalize_title("Onboarding Funnel (Copy)")        # -> "onboarding funnel"
    dup  = is_probable_duplicate("KPI Dashboard", "KPI Dashboard v2")  # -> True
    age  = days_since("2025-01-15T09:30:00Z")                 # -> int days, or None

Run `python3 dashboard_utils.py` to execute the built-in self-test.
"""

from __future__ import annotations

import re
from datetime import datetime, timezone
from difflib import SequenceMatcher

# Similarity at or above this ratio (on normalized titles) flags a duplicate.
DUPLICATE_RATIO_THRESHOLD = 0.80

# Trailing "(Copy)", "(Copy 2)", "(2)", "- Copy", "copy" suffixes.
_COPY_SUFFIX = re.compile(
    r"\s*(?:[-–—]\s*)?\(?\s*copy(?:\s*\d+)?\s*\)?$|\s*\(\s*\d+\s*\)$",
    re.IGNORECASE,
)
# Trailing dates like 2025-01-15, 2025/01, 01-15-2025, or "Jan 2025".
_TRAILING_DATE = re.compile(
    r"[\s\-_/]*"
    r"(?:\d{4}[-/]\d{1,2}(?:[-/]\d{1,2})?"
    r"|\d{1,2}[-/]\d{1,2}[-/]\d{2,4}"
    r"|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s*\d{2,4})"
    r"\s*$",
    re.IGNORECASE,
)


def normalize_title(title: str) -> str:
    """Lowercase and strip trailing (Copy)/(N) markers, trailing dates, and whitespace."""
    if not title:
        return ""
    t = title.strip()
    # Strip repeatedly: a title may carry both a date and a "(Copy)" suffix.
    prev = None
    while prev != t:
        prev = t
        t = _COPY_SUFFIX.sub("", t).strip()
        t = _TRAILING_DATE.sub("", t).strip()
    return re.sub(r"\s+", " ", t).strip().lower()


def title_similarity(a: str, b: str) -> float:
    """difflib ratio (0.0–1.0) of two normalized titles."""
    return SequenceMatcher(None, normalize_title(a), normalize_title(b)).ratio()


def is_probable_duplicate(a: str, b: str) -> bool:
    """True if two titles are likely duplicates.

    Match when normalized similarity >= DUPLICATE_RATIO_THRESHOLD, OR one
    normalized title is a (non-empty) substring of the other.
    """
    na, nb = normalize_title(a), normalize_title(b)
    if not na or not nb:
        return False
    if na in nb or nb in na:
        return True
    return SequenceMatcher(None, na, nb).ratio() >= DUPLICATE_RATIO_THRESHOLD


def days_since(timestamp, now: datetime | None = None):
    """Whole days between `timestamp` and now (UTC). Returns None if unparseable.

    Accepts ISO-8601 strings (with or without trailing 'Z'), epoch seconds
    (int/float), or a datetime.
    """
    now = now or datetime.now(timezone.utc)
    dt = _coerce_dt(timestamp)
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return (now - dt).days


def _coerce_dt(ts):
    if ts is None:
        return None
    if isinstance(ts, datetime):
        return ts
    if isinstance(ts, (int, float)):
        return datetime.fromtimestamp(ts, tz=timezone.utc)
    if isinstance(ts, str):
        s = ts.strip().replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(s)
        except ValueError:
            for fmt in ("%Y-%m-%d", "%Y/%m/%d", "%m/%d/%Y"):
                try:
                    return datetime.strptime(ts.strip(), fmt)
                except ValueError:
                    continue
    return None


def _selftest():
    assert normalize_title("Onboarding Funnel (Copy)") == "onboarding funnel"
    assert normalize_title("KPI Dashboard (2)") == "kpi dashboard"
    assert normalize_title("Revenue 2025-01-15") == "revenue"
    assert normalize_title("Weekly Metrics - Copy") == "weekly metrics"
    assert normalize_title("Q3 Review Jan 2025") == "q3 review"

    assert is_probable_duplicate("Onboarding Funnel", "Onboarding Funnel (Copy)")
    assert is_probable_duplicate("KPI Dashboard", "KPI Dashboard v2")  # substring
    assert is_probable_duplicate("Retention Report", "Retention Reprot")  # ~0.93 ratio
    assert not is_probable_duplicate("Onboarding Funnel", "Revenue Overview")
    assert not is_probable_duplicate("", "Anything")

    now = datetime(2026, 6, 9, tzinfo=timezone.utc)
    assert days_since("2026-03-11T00:00:00Z", now=now) == 90
    assert days_since("2026/06/09", now=now) == 0
    assert days_since("not-a-date") is None
    print("dashboard_utils self-test: PASS")


if __name__ == "__main__":
    _selftest()
