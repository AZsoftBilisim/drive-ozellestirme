// Extension (Shamsidate) -> Common forms -> sh_ShamsiDatePicker -> Module
// Formun TÜM modül içeriği. (v8.1 - küçük HTML takvim)
//
// Designer'da (bir kez, zaten yaptıysanız tekrar gerekmez):
//   1. Formun "Parameters" sekmesinde parametre:  Date  (tip: Date)
//   2. Form özelliklerinde Events -> OnCreateAtServer -> "OnCreateAtServer"
// Form üzerinde başka eleman olmamalı; takvim koddan oluşturulur.

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Attrs = New Array;
	Attrs.Add(New FormAttribute("HtmlText", New TypeDescription("String")));
	ChangeAttributes(Attrs);
	
	Initial = Undefined;
	Parameters.Property("Date", Initial);
	SelText = "";
	If TypeOf(Initial) = Type("Date") And Year(Initial) >= 1000 Then
		SelText = Format(Initial, "DF=yyyy-MM-dd");
	EndIf;
	
	Html = HtmlTemplate();
	Html = StrReplace(Html, "__SEL__", SelText);
	Html = StrReplace(Html, "__TODAY__", Format(CurrentSessionDate(), "DF=yyyy-MM-dd"));
	ThisObject["HtmlText"] = Html;
	
	Title = NStr("en = 'Shamsi calendar'; tr = 'Şemsi takvim'; fa = 'تقویم شمسی'; ru = 'Календарь Шамси'");
	AutoTitle = False;
	WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	Width = 46;
	Height = 34;
	// "More actions" komut çubuğunu gizle
	Try
		ThisObject.CommandBar.Visible = False;
	Except
	EndTry;
	
	Fld = Items.Add("Calendar", Type("FormField"));
	Fld.Type = FormFieldType.HTMLDocumentField;
	Fld.DataPath = "HtmlText";
	Fld.TitleLocation = FormItemTitleLocation.None;
	Fld.HorizontalStretch = True;
	Fld.VerticalStretch = True;
	Fld.SetAction("OnClick", "CalendarOnClick");
	
EndProcedure

// Takvimde bir güne tıklanınca: seçilen tarihi Şemsi metin olarak alana döndürür.
// Ay/yıl gezinmesi tamamen HTML içinde (JavaScript) yapılır.
&AtClient
Procedure CalendarOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	Code = "";
	
	Try
		Href = EventData.Href;
		If ValueIsFilled(Href) Then
			Pos = StrFind(Href, "#p");
			If Pos > 0 Then
				Code = Mid(Href, Pos + 2, 8);
			EndIf;
		EndIf;
	Except
	EndTry;
	
	If StrLen(Code) <> 8 Then
		Try
			ElementId = EventData.Element.id;
			If StrStartsWith(ElementId, "p") Then
				Code = Mid(ElementId, 2, 8);
			EndIf;
		Except
		EndTry;
	EndIf;
	
	If StrLen(Code) <> 8 Then
		Return;
	EndIf;
	
	Try
		Picked = Date(Number(Left(Code, 4)), Number(Mid(Code, 5, 2)), Number(Right(Code, 2)));
	Except
		Return;
	EndTry;
	
	NotifyChoice(sh_ShamsiCalendar.GregorianToShamsi(Picked));
	
EndProcedure

&AtServerNoContext
Function HtmlTemplate()
	Return "<!DOCTYPE html>
	|<html dir=""rtl"">
	|<head>
	|<meta charset=""utf-8"">
	|<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"">
	|<style>
	|* { box-sizing: border-box; }
	|html, body { margin: 0; padding: 0; overflow: hidden; background: #f4f4f4; font-family: Tahoma, 'Segoe UI', Arial, sans-serif; color: #333; user-select: none; }
	|.wrap { width: 340px; margin: 0 auto; padding: 4px 6px 6px; }
	|.top { text-align: center; position: relative; }
	|.title { font-size: 16px; font-weight: bold; color: #8a3300; }
	|.title a { margin: 0 2px; vertical-align: middle; }
	|.dd { display: inline-block; width: 18px; height: 18px; line-height: 14px; border: 2px solid #8a3300; border-radius: 50%; font-size: 10px; color: #8a3300; text-decoration: none; text-align: center; }
	|.tlink { color: #8a3300; text-decoration: none; }
	|.nav { width: 100%; margin-top: 3px; font-size: 11px; border-collapse: collapse; }
	|.nav td { padding: 0; }
	|.nav a { color: #333; text-decoration: none; }
	|.nav a b { color: #b03a00; }
	|.sub { font-size: 11px; color: #444; margin-top: 2px; direction: ltr; }
	|.sub2 { font-size: 11px; color: #666; margin-top: 2px; }
	|.card { background: #fff; border-radius: 8px; padding: 6px 6px 2px; margin-top: 6px; }
	|.head { width: 100%; background: #8a3300; color: #fff; border-radius: 6px; font-weight: bold; font-size: 12px; text-align: center; border-collapse: collapse; }
	|.head td { padding: 4px 0; width: 14.28%; }
	|.grid { width: 100%; margin-top: 8px; border-collapse: separate; border-spacing: 3px 4px; table-layout: fixed; }
	|.grid td { padding: 0; }
	|.cell { display: block; text-decoration: none; color: #333; text-align: center; padding: 2px 0 1px; border-radius: 5px; border: 2px solid transparent; }
	|.cell span { pointer-events: none; display: block; }
	|.cell .n { font-size: 15px; font-weight: bold; line-height: 18px; }
	|.cell .s { font-size: 9px; color: #777; margin-top: 0; line-height: 11px; }
	|.cell .s span { display: inline; margin: 0 2px; }
	|.cell.out .n { color: #aaa; }
	|.cell.out .s { color: #bbb; }
	|.cell.hol { background: #fdeeee; }
	|.cell.hol .n, .cell.hol .s { color: #d0021b; }
	|.cell.hol.out .n, .cell.hol.out .s { color: #e88a95; }
	|.cell.today { border-color: #a0400a; }
	|.cell.sel { background: #f6e3d6; }
	|.cell:hover { background: #f1e6de; }
	|.btn { display: block; margin-top: 6px; background: #b03a00; color: #fff; text-align: center; padding: 6px; border-radius: 6px; font-weight: bold; text-decoration: none; font-size: 12px; }
	|.overlay { display: none; position: absolute; left: 40px; top: 26px; background: #fff; border: 1px solid #ddd; border-radius: 8px; box-shadow: 0 4px 14px rgba(0,0,0,.15); padding: 8px; z-index: 10; width: 260px; }
	|.overlay.show { display: block; }
	|.overlay a { display: inline-block; width: 30%; margin: 3px 1%; text-decoration: none; color: #333; padding: 6px 0; border-radius: 6px; font-size: 12px; text-align: center; }
	|.overlay a:hover, .overlay a.cur { background: #8a3300; color: #fff; }
	|</style>
	|</head>
	|<body>
	|<div class=""wrap"">
	|  <div class=""top"">
	|    <div class=""title"">
	|      <a class=""dd"" href=""#"" onclick=""toggleMonths();return false;"">&#8964;</a>
	|      <a class=""tlink"" href=""#"" onclick=""toggleMonths();return false;"" id=""mName""></a>
	|      <a class=""tlink"" href=""#"" onclick=""toggleYears();return false;"" id=""yName""></a>
	|      <a class=""dd"" href=""#"" onclick=""toggleYears();return false;"">&#8964;</a>
	|    </div>
	|    <div class=""overlay"" id=""ovM""></div>
	|    <div class=""overlay"" id=""ovY""></div>
	|    <table class=""nav""><tr>
	|      <td style=""text-align:right;width:25%""><a href=""#"" onclick=""move(-1);return false;""><b>&#10140;</b> ماه قبل</a></td>
	|      <td style=""text-align:center""><div class=""sub"" id=""gRange""></div></td>
	|      <td style=""text-align:left;width:25%""><a href=""#"" onclick=""move(1);return false;"">ماه بعد <b>&#10140;</b></a></td>
	|    </tr></table>
	|    <div class=""sub2"" id=""hRange""></div>
	|  </div>
	|  <div class=""card"">
	|    <table class=""head""><tr><td>ش</td><td>ی</td><td>د</td><td>س</td><td>چ</td><td>پ</td><td>ج</td></tr></table>
	|    <div id=""grid""></div>
	|  </div>
	|  <a class=""btn"" href=""#"" onclick=""goToday();return false;"">برو به امروز</a>
	|</div>
	|<script>
	|// ---- Ayarlar (1C tarafından doldurulur)
	|var SEL = '__SEL__';      // seçili miladi tarih yyyy-mm-dd (boş olabilir)
	|var TODAY = '__TODAY__';  // bugünün miladi tarihi yyyy-mm-dd
	|var HOLIDAY_COLS = [5, 6];// 0 = Şenbe ... 5 = Perşembe, 6 = Cuma
	|var HIJRI_OFFSET = 1;     // İran resmi kameri takvimi ile tablo yöntemi arasındaki fark (gün)
	|
	|var FA_MONTHS = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور','مهر','آبان','آذر','دی','بهمن','اسفند'];
	|var HI_MONTHS = ['محرم','صفر','ربیع الاول','ربیع الثانی','جمادی الاول','جمادی الثانیه','رجب','شعبان','رمضان','شوال','ذی القعده','ذی الحجه'];
	|var GR_MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
	|
	|function fa(n) { return String(n).replace(/[0-9]/g, function (d) { return '۰۱۲۳۴۵۶۷۸۹'.charAt(+d); }); }
	|function div(a, b) { return Math.floor(a / b); }
	|
	|// Miladi <-> Jülyen gün numarası
	|function g2jd(y, m, d) { var a = div(14 - m, 12), y2 = y + 4800 - a, m2 = m + 12 * a - 3;
	|  return d + div(153 * m2 + 2, 5) + 365 * y2 + div(y2, 4) - div(y2, 100) + div(y2, 400) - 32045; }
	|function jd2g(jd) { var a = jd + 32044, b = div(4 * a + 3, 146097), c = a - div(146097 * b, 4),
	|  d = div(4 * c + 3, 1461), e = c - div(1461 * d, 4), m = div(5 * e + 2, 153);
	|  return [100 * b + d - 4800 + div(m, 10), m + 3 - 12 * div(m, 10), e - div(153 * m + 2, 5) + 1]; }
	|
	|// Şemsi (1C modülündeki algoritmanın aynısı)
	|function g2j(gy, gm, gd) {
	|  var gdm = [0,31,59,90,120,151,181,212,243,273,304,334], gy2 = gm > 2 ? gy + 1 : gy;
	|  var days = 355666 + 365 * gy + div(gy2 + 3, 4) - div(gy2 + 99, 100) + div(gy2 + 399, 400) + gd + gdm[gm - 1];
	|  var jy = -1595 + 33 * div(days, 12053); days %= 12053; jy += 4 * div(days, 1461); days %= 1461;
	|  if (days > 365) { jy += div(days - 1, 365); days = (days - 1) % 365; }
	|  var jm, jd; if (days < 186) { jm = 1 + div(days, 31); jd = 1 + days % 31; } else { jm = 7 + div(days - 186, 30); jd = 1 + (days - 186) % 30; }
	|  return [jy, jm, jd]; }
	|function j2jd(jy, jm, jd) { var y = jy + 1595;
	|  var days = -355668 + 365 * y + div(y, 33) * 8 + div(y % 33 + 3, 4) + jd + (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
	|  return days + 1721060; }
	|function monthLen(jy, jm) { if (jm <= 6) return 31; if (jm <= 11) return 30;
	|  var g = jd2g(j2jd(jy, 12, 30)), b = g2j(g[0], g[1], g[2]); return (b[1] === 12) ? 30 : 29; }
	|
	|// Kameri (tablo yöntemi + düzeltme)
	|function isl2jd(y, m, d) { return d + Math.ceil(29.5 * (m - 1)) + (y - 1) * 354 + div(3 + 11 * y, 30) + 1948439; }
	|function jd2isl(jd) { jd = jd + HIJRI_OFFSET; var y = div(30 * (jd - 1948440) + 10646, 10631);
	|  var m = Math.min(12, Math.ceil((jd - (29 + isl2jd(y, 1, 1))) / 29.5) + 1); return [y, m, jd - isl2jd(y, m, 1) + 1]; }
	|
	|function parse(s) { if (!s || s.length < 10) return null; return [+s.substr(0, 4), +s.substr(5, 2), +s.substr(8, 2)]; }
	|function pad(n) { return (n < 10 ? '0' : '') + n; }
	|
	|var todayG = parse(TODAY), selG = parse(SEL);
	|var todayJD = g2jd(todayG[0], todayG[1], todayG[2]);
	|var selJD = selG ? g2jd(selG[0], selG[1], selG[2]) : -1;
	|var startJ = g2j.apply(null, selG || todayG);
	|var curY = startJ[0], curM = startJ[1];
	|
	|function render() {
	|  document.getElementById('mName').innerHTML = FA_MONTHS[curM - 1];
	|  document.getElementById('yName').innerHTML = fa(curY);
	|  var first = j2jd(curY, curM, 1), len = monthLen(curY, curM);
	|  var wd = (first + 2) % 7;                 // 0 = Şenbe
	|  var start = first - wd, cells = Math.ceil((wd + len) / 7) * 7, html = '';
	|  for (var i = 0; i < cells; i++) {
	|    var jd = start + i, g = jd2g(jd), j = g2j(g[0], g[1], g[2]), h = jd2isl(jd);
	|    var cls = 'cell';
	|    if (jd < first || jd >= first + len) cls += ' out';
	|    if (HOLIDAY_COLS.indexOf(i % 7) >= 0) cls += ' hol';
	|    if (jd === todayJD) cls += ' today';
	|    if (jd === selJD) cls += ' sel';
	|    if (i % 7 === 0) html += '<tr>';
	|    html += '<td><a class=""' + cls + '"" id=""p' + g[0] + pad(g[1]) + pad(g[2]) + '"" href=""#p' + g[0] + pad(g[1]) + pad(g[2]) + '"">' +
	|      '<span class=""n"">' + fa(j[2]) + '</span><span class=""s""><span>' + fa(h[2]) + '</span><span>' + g[2] + '</span></span></a></td>';
	|    if (i % 7 === 6) html += '</tr>';
	|  }
	|  document.getElementById('grid').innerHTML = '<table class=""grid"">' + html + '</table>';
	|  var g1 = jd2g(first), g2 = jd2g(first + len - 1), h1 = jd2isl(first), h2 = jd2isl(first + len - 1);
	|  document.getElementById('gRange').innerHTML = GR_MONTHS[g1[1] - 1] + (g1[0] !== g2[0] ? ' ' + g1[0] : '') + ' - ' + GR_MONTHS[g2[1] - 1] + ' ' + g2[0];
	|  document.getElementById('hRange').innerHTML = HI_MONTHS[h1[1] - 1] + (h1[0] !== h2[0] ? ' ' + fa(h1[0]) : '') + ' - ' + HI_MONTHS[h2[1] - 1] + ' ' + fa(h2[0]);
	|  hideOverlays();
	|}
	|function move(k) { curM += k; if (curM < 1) { curM = 12; curY--; } if (curM > 12) { curM = 1; curY++; } render(); }
	|function goToday() { var t = g2j(todayG[0], todayG[1], todayG[2]); curY = t[0]; curM = t[1]; render(); }
	|function hideOverlays() { document.getElementById('ovM').className = 'overlay'; document.getElementById('ovY').className = 'overlay'; }
	|function toggleMonths() { var o = document.getElementById('ovM'), h = '';
	|  for (var m = 1; m <= 12; m++) h += '<a href=""#"" class=""' + (m === curM ? 'cur' : '') + '"" onclick=""curM=' + m + ';render();return false;"">' + FA_MONTHS[m - 1] + '</a>';
	|  o.innerHTML = h; var show = o.className.indexOf('show') < 0; hideOverlays(); if (show) o.className = 'overlay show'; }
	|function toggleYears() { var o = document.getElementById('ovY'), h = '';
	|  for (var y = curY - 7; y <= curY + 7; y++) h += '<a href=""#"" class=""' + (y === curY ? 'cur' : '') + '"" onclick=""curY=' + y + ';render();return false;"">' + fa(y) + '</a>';
	|  o.innerHTML = h; var show = o.className.indexOf('show') < 0; hideOverlays(); if (show) o.className = 'overlay show'; }
	|render();
	|</script>
	|</body>
	|</html>";
EndFunction
