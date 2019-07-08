<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <!-- date range as monthName dayNum - monthName dayNum year -->
  <xsl:variable name="datePattern01">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s([\d]{1,2})\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s([\d]{1,2})\s?,?\s([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date range as monthName - monthName year -->
  <xsl:variable name="datePattern02">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?),?\s([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date range as monthName year - monthName year -->
  <xsl:variable name="datePattern03">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?),?\s([012]\d{3})\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?),?\s([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date range as monthName dayNum - dayNum year -->
  <xsl:variable name="datePattern04">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s([\d]{1,2})\s?-\s?([\d]{1,2})\s?,?\s([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName dayNum - year monthName dayNum -->
  <xsl:variable name="datePattern05">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[\d]{1,2}\s?-\s?[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[\d]{1,2}</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName - year monthName -->
  <xsl:variable name="datePattern06">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s?-\s?[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName - year -->
  <xsl:variable name="datePattern07">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s?-\s?[012]\d{3}</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName - monthName -->
  <xsl:variable name="datePattern08">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName dayNum - monthName dayNum -->
  <xsl:variable name="datePattern09">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[\d]{1,2}\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[\d]{1,2}</xsl:text>
  </xsl:variable>
  
  <!-- date range as year monthName dayNum - dayNum -->
  <xsl:variable name="datePattern10">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[\d]{1,2}\s?-\s?[\d]{1,2}</xsl:text>
  </xsl:variable>
  
  <!-- date range as monthNum/dayNum/year - monthNum/dayNum/year -->
  <xsl:variable name="datePattern11">
    <xsl:text>(0[1-9]|[1-9]|1[012])[-/]([1-9]|[12][0-9]|3[01])[-/]([012]\d{3})\s?-\s?(0[1-9]|[1-9]|1[012])[-/]([1-9]|[12][0-9]|3[01])[-/]([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date range as year - year monthName -->
  <xsl:variable name="datePattern12">
    <xsl:text>[012]\d{3}\s?-\s?[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)</xsl:text>
  </xsl:variable>
  
  <!-- date range as year - year, either year optionally qualified with '?' -->
  <xsl:variable name="datePattern13">
    <xsl:text>[012]\d{3}\??\s?-\s?[012]\d{3}\??</xsl:text>
  </xsl:variable>
  
  <!-- date range as year - year, decades optionally qualified with 's' -->
  <xsl:variable name="datePattern14">
    <xsl:text>[012]\d{2}(0s?|[1-9])\s?-\s?[012]\d{2}(0s?|[1-9])</xsl:text>
  </xsl:variable>
  
  <!-- date range as date qualified by 's' -->
  <xsl:variable name="datePattern15">
    <xsl:text>[012]\d{2}0s</xsl:text>
  </xsl:variable>
  
  <!-- date range as 4-digit year - 2-digit year or month -->
  <xsl:variable name="datePattern16">
    <xsl:text>[012]\d{3}\s?-\s?[\d]{2}</xsl:text>
  </xsl:variable>
  
  <!-- date range as dayNum - dayNum monthName year -->
  <xsl:variable name="datePattern17">
    <xsl:text>[\d]{1,2}\s?-\s?[\d]{1,2}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[012]\d{3}</xsl:text>
  </xsl:variable>
  
  <!-- date range as year - monthName year -->
  <xsl:variable name="datePattern18">
    <xsl:text>[012]\d{3}\s?-\s?(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[012]\d{3}</xsl:text>
  </xsl:variable>
  
  <!-- date as dayNum monthName year -->
  <xsl:variable name="datePattern19">
    <xsl:text>[\d]{1,2}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[012]\d{3}</xsl:text>
  </xsl:variable>
  
  <!-- date as monthName dayNum, year -->
  <xsl:variable name="datePattern20">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s([\d]{1,2})\s?,?\s([012]\d{3})</xsl:text>
  </xsl:variable>
  
  <!-- date as monthName year -->
  <xsl:variable name="datePattern21">
    <xsl:text>(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s[012]\d{3}</xsl:text>
  </xsl:variable>
  
  <!-- date as monthNum/dayNum/year -->
  <xsl:variable name="datePattern22">
    <xsl:text>(0[1-9]|[1-9]|1[012])[-/]([1-9]|[12][0-9]|3[01])[-/](\d{2}|\d{4})</xsl:text>
  </xsl:variable>
  
  <!-- date as year-monthNum-dayNum, with optional time -->
  <xsl:variable name="datePattern23">
    <xsl:text>([012]\d{3})[-/](0[1-9]|1[012])[-/](0[1-9]|[12][0-9]|3[01])(\s\d{2}:\d{2}:\d{2}(\s?[\-\+]\d{4})?)?</xsl:text>
  </xsl:variable>
  
  <!-- date as year seasonName/holiday -->
  <xsl:variable name="datePattern24">
    <xsl:text>([012]\d{3})\s(Spring|Summer|Fall|Winter|Christmas|Easter|Thanksgiving)</xsl:text>
  </xsl:variable>
  
  <!-- date as seasonName/holiday year -->
  <xsl:variable name="datePattern25">
    <xsl:text>(Spring|Summer|Fall|Winter|Christmas|Easter|Thanksgiving)\s([012]\d{3})(-\d{2,4})?</xsl:text>
  </xsl:variable>
  
  <!-- date as year monthName dayNum -->
  <xsl:variable name="datePattern26">
    <xsl:text>([012]\d{3})\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)\s([\d]{1,2})</xsl:text>
  </xsl:variable>
  
  <!-- date as year monthName (no dayNum) -->
  <xsl:variable name="datePattern27">
    <xsl:text>[012]\d{3}\s(Jan(\.|uary)?|Feb(\.|ruary)?|Mar(\.|ch)?|Apr(\.|il)?|May|Jun(\.|e)?|Jul(\.|y)?|Aug(\.|ust)?|Sep(\.|t(\.|ember)?)?|Oct(\.|ober)?|Nov(\.|ember)?|Dec(\.|ember)?)</xsl:text>
  </xsl:variable>
  
  <!-- date as year only -->
  <xsl:variable name="datePattern28">
    <xsl:text>[012][\d]{3}</xsl:text>
  </xsl:variable>
  
  <!-- date as year with decade precision -->
  <xsl:variable name="datePattern29">
    <xsl:text>[012][\d]{2}[-u\?]</xsl:text>
  </xsl:variable>
  
  <!-- date as year with century precision -->
  <xsl:variable name="datePattern30">
    <xsl:text>[012][\d][-u\?]{2}</xsl:text>
  </xsl:variable>
  
  <!-- date as year with millenium precision -->
  <xsl:variable name="datePattern31">
    <xsl:text>[012][-u\?]{3}</xsl:text>
  </xsl:variable>
  
  <!-- date as ordinal century -->
  <xsl:variable name="datePattern32">
    <xsl:text>(\d+)(st|nd|rd|th)\sc(\.|(en(t(u(r(y)?)?)?)?))</xsl:text>
  </xsl:variable>
  
  <!-- undated -->
  <xsl:variable name="datePattern33">
    <xsl:text>(undated|no date|n\.\s?d\.)</xsl:text>
  </xsl:variable>
  
  <xsl:variable name="datePatternLeading">
    <xsl:text>[\[\(]?((ca\.|circa|early|late|mid-?)\s?)?</xsl:text>
  </xsl:variable>
  
  <xsl:variable name="datePatternTrailing">
    <xsl:text>[\s\?]?[\]\)]?</xsl:text>
  </xsl:variable>
  
  <xsl:variable name="datePatterns">
    <xsl:value-of
      select="
      concat($datePatternLeading, '(',
      string-join(($datePattern01, $datePattern02, $datePattern03, $datePattern04, $datePattern05,
      $datePattern06, $datePattern07, $datePattern08, $datePattern09, $datePattern10, $datePattern11,
      $datePattern12, $datePattern13, $datePattern14, $datePattern15, $datePattern16, $datePattern17,
      $datePattern18, $datePattern19, $datePattern20, $datePattern21, $datePattern22, $datePattern23,
      $datePattern24, $datePattern25, $datePattern26, $datePattern27, $datePattern28, $datePattern29,
      $datePattern30, $datePattern31, $datePattern32, $datePattern33), '|'), ')', $datePatternTrailing)"
    />
  </xsl:variable>
  
</xsl:stylesheet>