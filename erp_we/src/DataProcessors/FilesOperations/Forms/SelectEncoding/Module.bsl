///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentEncoding = Parameters.CurrentEncoding;
	
	ShowOnlyPrimaryEncodings = True;
	FillEncodingsList(Not ShowOnlyPrimaryEncodings);
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowOnlyPrimaryEncodingsOnChange(Item)
	
	FillEncodingsList(Not ShowOnlyPrimaryEncodings);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEncodingsList

&AtClient
Procedure EncodingsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CloseFormWithEncodingReturn();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectEncoding(Command)
	
	CloseFormWithEncodingReturn();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CloseFormWithEncodingReturn()
	
	Presentation = Items.EncodingsList.CurrentData.Presentation;
	If Not ValueIsFilled(Presentation) Then
		Presentation = Items.EncodingsList.CurrentData.Value;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("Value", Items.EncodingsList.CurrentData.Value);
	SelectionResult.Insert("Presentation", Presentation);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtServer
Procedure FillEncodingsList(FullList)
	
	ElementID = Undefined;
	EncodingsListLocal = Undefined;
	EncodingsList.Clear();
	
	If Not FullList Then
		EncodingsListLocal = FilesOperationsInternal.Encodings();
	Else
		EncodingsListLocal = GetFullEncodingsList();
	EndIf;
	
	For Each Encoding In EncodingsListLocal Do
		
		ListItem = EncodingsList.Add(Encoding.Value, Encoding.Presentation);
		
		If Lower(Encoding.Value) = Lower(CurrentEncoding) Then
			ElementID = ListItem.GetID();
		EndIf;
		
	EndDo;
	
	If ElementID <> Undefined Then
		Items.EncodingsList.CurrentRow = ElementID;
	EndIf;
	
EndProcedure

// Returns a table of encoding names.
//
// Returns:
//   ValueTable
//
&AtServerNoContext
Function GetFullEncodingsList()

	EncodingsList = New ValueList;
	
	EncodingsList.Add("Adobe-Standard-Encoding");
	EncodingsList.Add("Big5");
	EncodingsList.Add("Big5-HKSCS");
	EncodingsList.Add("BOCU-1");
	EncodingsList.Add("CESU-8");
	EncodingsList.Add("cp1006");
	EncodingsList.Add("cp1025");
	EncodingsList.Add("cp1097");
	EncodingsList.Add("cp1098");
	EncodingsList.Add("cp1112");
	EncodingsList.Add("cp1122");
	EncodingsList.Add("cp1123");
	EncodingsList.Add("cp1124");
	EncodingsList.Add("cp1125");
	EncodingsList.Add("cp1131");
	EncodingsList.Add("cp1386");
	EncodingsList.Add("cp33722");
	EncodingsList.Add("cp437");
	EncodingsList.Add("cp737");
	EncodingsList.Add("cp775");
	EncodingsList.Add("cp850");
	EncodingsList.Add("cp851");
	EncodingsList.Add("cp852");
	EncodingsList.Add("cp855");
	EncodingsList.Add("cp856");
	EncodingsList.Add("cp857");
	EncodingsList.Add("cp858");
	EncodingsList.Add("cp860");
	EncodingsList.Add("cp861");
	EncodingsList.Add("cp862");
	EncodingsList.Add("cp863");
	EncodingsList.Add("cp864");
	EncodingsList.Add("cp865");
	EncodingsList.Add("cp866",   NStr("vi = 'CP866 (Cyrillic DOS)';
										|ru = 'CP866 (Кириллица DOS)';
										|en = 'CP866 (Cyrillic DOS)'; fa = 'CP866 (Cyrillic DOS)';
										|it = 'CP866 (Alfabeto cirillico DOS)';
										|pl = 'CP866 (Cyrylica DOS)';
										|tr = 'CP866 (Kiril DOS)'"));
	EncodingsList.Add("cp868");
	EncodingsList.Add("cp869");
	EncodingsList.Add("cp874");
	EncodingsList.Add("cp875");
	EncodingsList.Add("cp922");
	EncodingsList.Add("cp930");
	EncodingsList.Add("cp932");
	EncodingsList.Add("cp933");
	EncodingsList.Add("cp935");
	EncodingsList.Add("cp937");
	EncodingsList.Add("cp939");
	EncodingsList.Add("cp949");
	EncodingsList.Add("cp949c");
	EncodingsList.Add("cp950");
	EncodingsList.Add("cp964");
	EncodingsList.Add("ebcdic-ar");
	EncodingsList.Add("ebcdic-de");
	EncodingsList.Add("ebcdic-dk");
	EncodingsList.Add("ebcdic-he");
	EncodingsList.Add("ebcdic-xml-us");
	EncodingsList.Add("EUC-JP");
	EncodingsList.Add("EUC-KR");
	EncodingsList.Add("GB_2312-80");
	EncodingsList.Add("gb18030");
	EncodingsList.Add("GB2312");
	EncodingsList.Add("GBK");
	EncodingsList.Add("hp-roman8");
	EncodingsList.Add("HZ-GB-2312");
	EncodingsList.Add("IBM01140");
	EncodingsList.Add("IBM01141");
	EncodingsList.Add("IBM01142");
	EncodingsList.Add("IBM01143");
	EncodingsList.Add("IBM01144");
	EncodingsList.Add("IBM01145");
	EncodingsList.Add("IBM01146");
	EncodingsList.Add("IBM01147");
	EncodingsList.Add("IBM01148");
	EncodingsList.Add("IBM01149");
	EncodingsList.Add("IBM037");
	EncodingsList.Add("IBM1026");
	EncodingsList.Add("IBM1047");
	EncodingsList.Add("ibm-1047_P100-1995,swaplfnl");
	EncodingsList.Add("ibm-1129");
	EncodingsList.Add("ibm-1130");
	EncodingsList.Add("ibm-1132");
	EncodingsList.Add("ibm-1133");
	EncodingsList.Add("ibm-1137");
	EncodingsList.Add("ibm-1140_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1142_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1143_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1144_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1145_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1146_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1147_P100-1997,swaplfnl ");
	EncodingsList.Add("ibm-1148_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1149_P100-1997,swaplfnl");
	EncodingsList.Add("ibm-1153");
	EncodingsList.Add("ibm-1153_P100-1999,swaplfnl");
	EncodingsList.Add("ibm-1154");
	EncodingsList.Add("ibm-1155");
	EncodingsList.Add("ibm-1156");
	EncodingsList.Add("ibm-1157");
	EncodingsList.Add("ibm-1158");
	EncodingsList.Add("ibm-1160");
	EncodingsList.Add("ibm-1162");
	EncodingsList.Add("ibm-1164");
	EncodingsList.Add("ibm-12712_P100-1998,swaplfnl");
	EncodingsList.Add("ibm-1363");
	EncodingsList.Add("ibm-1364");
	EncodingsList.Add("ibm-1371");
	EncodingsList.Add("ibm-1388");
	EncodingsList.Add("ibm-1390");
	EncodingsList.Add("ibm-1399");
	EncodingsList.Add("ibm-16684");
	EncodingsList.Add("ibm-16804_X110-1999,swaplfnl");
	EncodingsList.Add("IBM278");
	EncodingsList.Add("IBM280");
	EncodingsList.Add("IBM284");
	EncodingsList.Add("IBM285");
	EncodingsList.Add("IBM290");
	EncodingsList.Add("IBM297");
	EncodingsList.Add("IBM367");
	EncodingsList.Add("ibm-37_P100-1995,swaplfnl");
	EncodingsList.Add("IBM420");
	EncodingsList.Add("IBM424");
	EncodingsList.Add("ibm-4899");
	EncodingsList.Add("ibm-4909");
	EncodingsList.Add("ibm-4971");
	EncodingsList.Add("IBM500");
	EncodingsList.Add("ibm-5123");
	EncodingsList.Add("ibm-803");
	EncodingsList.Add("ibm-8482");
	EncodingsList.Add("ibm-867");
	EncodingsList.Add("IBM870");
	EncodingsList.Add("IBM871");
	EncodingsList.Add("ibm-901");
	EncodingsList.Add("ibm-902");
	EncodingsList.Add("IBM918");
	EncodingsList.Add("ibm-971");
	EncodingsList.Add("IBM-Thai");
	EncodingsList.Add("IMAP-mailbox-name");
	EncodingsList.Add("ISO_2022,locale=ja,version=3");
	EncodingsList.Add("ISO_2022,locale=ja,version=4");
	EncodingsList.Add("ISO_2022,locale=ko,version=1");
	EncodingsList.Add("ISO-2022-CN");
	EncodingsList.Add("ISO-2022-CN-EXT");
	EncodingsList.Add("ISO-2022-JP");
	EncodingsList.Add("ISO-2022-JP-2");
	EncodingsList.Add("ISO-2022-KR");
	EncodingsList.Add("iso-8859-1",   NStr("vi = 'ISO-8859-1 (ISO Tây Âu)';
											|ru = 'ISO-8859-1 (Западноевропейская ISO)';
											|en = 'ISO-8859-1 (Western European ISO)'; fa = 'ISO-8859-1 (Western European ISO)';
											|it = 'iso-8859-1 (ISO dell''Europa occidentale)';
											|pl = 'iso-8859-1 (Europa Zachodnia ISO)';
											|tr = 'ISO-8859-1 (Batı Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-13");
	EncodingsList.Add("iso-8859-15");
	EncodingsList.Add("iso-8859-2",   NStr("vi = 'ISO-8859-2 (ISO Trung Âu)';
											|ru = 'ISO-8859-2 (Центральноевропейская ISO)';
											|en = 'ISO-8859-2 (Central European ISO)'; fa = 'ISO-8859-2 (Central European ISO)';
											|it = 'iso-8859-2 (ISO dell''Europa centrale)';
											|pl = 'iso-8859-2 (Europa środkowa ISO)';
											|tr = 'ISO-8859-2 (Orta Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-3",   NStr("vi = 'ISO-8859-3 (3 ISO Latin)';
											|ru = 'ISO-8859-3 (Латиница 3 ISO)';
											|en = 'ISO-8859-3 (Latin-3 ISO)'; fa = 'ISO-8859-3 (Latin-3 ISO)';
											|it = 'iso-8859-3 (Alfabeto latino 3 ISO)';
											|pl = 'iso-8859-3 (Łaciński 3 ISO)';
											|tr = 'ISO-8859-3 (Latin 3 ISO)'"));
	EncodingsList.Add("iso-8859-4",   NStr("vi = 'ISO-8859-4 (ISO Baltic)';
											|ru = 'ISO-8859-4 (Балтийская ISO)';
											|en = 'ISO-8859-4 (Baltic ISO)'; fa = 'ISO-8859-4 (Baltic ISO)';
											|it = 'iso-8859-4 (ISO del Baltico)';
											|pl = 'iso-8859-4 (Bałtycki ISO)';
											|tr = 'ISO-8859-4 (Baltik ISO)'"));
	EncodingsList.Add("iso-8859-5",   NStr("vi = 'ISO-8859-5 (ISO Cyrillic)';
											|ru = 'ISO-8859-5 (Кириллица ISO)';
											|en = 'ISO-8859-5 (Cyrillic ISO)'; fa = 'ISO-8859-5 (Cyrillic ISO)';
											|it = 'iso-8859-5 (Alfabeto cirillico ISO)';
											|pl = 'iso-8859-5 (Cyrylica ISO)';
											|tr = 'ISO-8859-5 (Kiril ISO)'"));
	EncodingsList.Add("iso-8859-6");
	EncodingsList.Add("iso-8859-7",   NStr("vi = 'ISO-8859-7 (ISO Hy Lạp)';
											|ru = 'ISO-8859-7 (Греческая ISO)';
											|en = 'ISO-8859-7 (Greek ISO)'; fa = 'ISO-8859-7 (Greek ISO)';
											|it = 'iso-8859-7 (ISO greca)';
											|pl = 'iso-8859-7 (Grecki ISO)';
											|tr = 'ISO-8859-7 (Yunan ISO)'"));
	EncodingsList.Add("iso-8859-8");
	EncodingsList.Add("iso-8859-9",   NStr("vi = 'ISO-8859-9 (ISO Thổ Nhĩ Kỳ)';
											|ru = 'ISO-8859-9 (Турецкая ISO)';
											|en = 'ISO-8859-9 (Turkish ISO)'; fa = 'ISO-8859-9 (Turkish ISO)';
											|it = 'iso-8859-9 (ISO turca)';
											|pl = 'iso-8859-9 (Turecki ISO)';
											|tr = 'ISO-8859-9 (Türkçe ISO)'"));
	EncodingsList.Add("JIS_Encoding");
	EncodingsList.Add("koi8-r",       NStr("vi = 'KOI8-R (KOI8-R Cyrillic)';
											|ru = 'KOI8-R (Кириллица KOI8-R)';
											|en = 'KOI8-R (Cyrillic KOI8-R)'; fa = 'KOI8-R (Cyrillic KOI8-R)';
											|it = 'koi8-r (Alfabeto cirillico KOI8-R)';
											|pl = 'koi8-r (Cyrylica KOI8-R)';
											|tr = 'KOI8-R (Kiril KOI8-R)'"));
	EncodingsList.Add("koi8-u",       NStr("vi = 'KOI8-U (KOI8-U Cyrillic)';
											|ru = 'KOI8-U (Кириллица KOI8-U)';
											|en = 'KOI8-U (Cyrillic KOI8-U)'; fa = 'KOI8-U (Cyrillic KOI8-U)';
											|it = 'koi8-u (Alfabeto cirillico KOI8-U)';
											|pl = 'koi8-u (Cyrylica KOI8-U)';
											|tr = 'KOI8-U (Kiril KOI8-U)'"));
	EncodingsList.Add("KSC_5601");
	EncodingsList.Add("LMBCS-1");
	EncodingsList.Add("LMBCS-11");
	EncodingsList.Add("LMBCS-16");
	EncodingsList.Add("LMBCS-17");
	EncodingsList.Add("LMBCS-18");
	EncodingsList.Add("LMBCS-19");
	EncodingsList.Add("LMBCS-2");
	EncodingsList.Add("LMBCS-3");
	EncodingsList.Add("LMBCS-4");
	EncodingsList.Add("LMBCS-5");
	EncodingsList.Add("LMBCS-6");
	EncodingsList.Add("LMBCS-8");
	EncodingsList.Add("macintosh");
	EncodingsList.Add("SCSU");
	EncodingsList.Add("Shift_JIS");
	EncodingsList.Add("us-ascii",     NStr("vi = 'US-ASCII (USA)';
											|ru = 'US-ASCII (США)';
											|en = 'US-ASCII (USA)'; fa = 'US-ASCII (USA)';
											|it = 'US-ASCII (USA)';
											|pl = 'US-ASCII (USA)';
											|tr = 'US-ASCII (ABD)'"));
	EncodingsList.Add("UTF-16");
	EncodingsList.Add("UTF16_OppositeEndian");
	EncodingsList.Add("UTF16_PlatformEndian");
	EncodingsList.Add("UTF-16BE");
	EncodingsList.Add("UTF-16LE");
	EncodingsList.Add("UTF-32");
	EncodingsList.Add("UTF32_OppositeEndian");
	EncodingsList.Add("UTF32_PlatformEndian");
	EncodingsList.Add("UTF-32BE");
	EncodingsList.Add("UTF-32LE");
	EncodingsList.Add("UTF-7");
	EncodingsList.Add("UTF-8",        NStr("vi = 'UTF-8 (Unicode UTF-8)';
											|ru = 'UTF-8 (Юникод UTF-8)';
											|en = 'UTF-8 (Unicode UTF-8)'; fa = 'UTF-8 (Unicode UTF-8)';
											|it = 'utf-8 (Unicode UTF-8)';
											|pl = 'utf-8 (Unikod UTF-8)';
											|tr = 'UTF-8 (Unicode UTF-8)'"));
	EncodingsList.Add("windows-1250", NStr("vi = 'Windows-1250 (Windows Trung Âu)';
											|ru = 'Windows-1250 (Центральноевропейская Windows)';
											|en = 'Windows-1250 (Central European Windows)'; fa = 'Windows-1250 (Central European Windows)';
											|it = 'wndows-1250 (Windows dell''Europa centrale)';
											|pl = 'Windows-1250 (Europa Środkowa Windows)';
											|tr = 'Windows-1250 (Orta Avrupa Windows)'"));
	EncodingsList.Add("windows-1251", NStr("vi = 'windows-1251 (Windows Cyrillic)';
											|ru = 'Windows-1251 (Кириллица Windows)';
											|en = 'Windows-1251 (Cyrillic Windows)'; fa = 'Windows-1251 (Cyrillic Windows)';
											|it = 'windows-1251 (Alfabeto cirillico Windows)';
											|pl = 'Windows-1251 (Cyrylica Windows)';
											|tr = 'Windows-1251 (Kiril Windows)'"));
	EncodingsList.Add("windows-1252", NStr("vi = 'Windows-1252 (Windows Tây Âu)';
											|ru = 'Windows-1252 (Западноевропейская Windows)';
											|en = 'Windows-1252 (Western European Windows)'; fa = 'Windows-1252 (Western European Windows)';
											|it = 'windows-1252 (Windows dell''Europa occidentale)';
											|pl = 'Windows-1252 (Europa Zachodnia Windows)';
											|tr = 'Windows-1252 (Batı Avrupa Windows)'"));
	EncodingsList.Add("windows-1253", NStr("vi = 'Windows-1253 (Windows Hy Lạp)';
											|ru = 'Windows-1253 (Греческая Windows)';
											|en = 'Windows-1253 (Greek Windows)'; fa = 'Windows-1253 (Greek Windows)';
											|it = 'windows-1253 (Windows greco)';
											|pl = 'Windows-1253 (Grecki Windows)';
											|tr = 'Windows-1253 (Yunan Windows)'"));
	EncodingsList.Add("windows-1254", NStr("vi = 'Windows-1254 (Windows Thổ Nhĩ Kỳ)';
											|ru = 'Windows-1254 (Турецкая Windows)';
											|en = 'Windows-1254 (Turkish Windows)'; fa = 'Windows-1254 (Turkish Windows)';
											|it = 'windows-1254 (Windows turco)';
											|pl = 'Windows-1254 (Turecki Windows)';
											|tr = 'Windows-1254 (Türkçe Windows)'"));
	EncodingsList.Add("windows-1255");
	EncodingsList.Add("windows-1256");
	EncodingsList.Add("windows-1257", NStr("vi = 'Windows-1257 (Windows Baltic)';
											|ru = 'Windows-1257 (Балтийская Windows)';
											|en = 'Windows-1257 (Baltic Windows)'; fa = 'Windows-1257 (Baltic Windows)';
											|it = 'windows-1257 (Windows baltico)';
											|pl = 'Windows-1257 (Bałtycki Windows)';
											|tr = 'Windows-1257 (Baltik Windows)'"));
	EncodingsList.Add("windows-1258");
	EncodingsList.Add("windows-57002");
	EncodingsList.Add("windows-57003");
	EncodingsList.Add("windows-57004");
	EncodingsList.Add("windows-57005");
	EncodingsList.Add("windows-57007");
	EncodingsList.Add("windows-57008");
	EncodingsList.Add("windows-57009");
	EncodingsList.Add("windows-57010");
	EncodingsList.Add("windows-57011");
	EncodingsList.Add("windows-874");
	EncodingsList.Add("windows-949");
	EncodingsList.Add("windows-950");
	EncodingsList.Add("x-mac-centraleurroman");
	EncodingsList.Add("x-mac-cyrillic");
	EncodingsList.Add("x-mac-greek");
	EncodingsList.Add("x-mac-turkish");
	
	Return EncodingsList;

EndFunction

#EndRegion
