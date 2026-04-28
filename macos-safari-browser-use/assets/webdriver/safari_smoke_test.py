#!/usr/bin/env python3
"""Minimal Safari WebDriver smoke test.

Prerequisites:
  1. Run: /usr/bin/safaridriver --enable
  2. Install Selenium in your project environment: python3 -m pip install selenium

This file is an asset template. Copy it into a project test directory and adapt.
"""

from __future__ import annotations

from selenium import webdriver
from selenium.webdriver.safari.options import Options


def main() -> None:
    options = Options()
    driver = webdriver.Safari(options=options)
    try:
        driver.get("https://example.com/")
        assert "Example" in driver.title, driver.title
        heading = driver.find_element("css selector", "h1").text
        print({"success": True, "title": driver.title, "heading": heading})
    finally:
        driver.quit()


if __name__ == "__main__":
    main()
