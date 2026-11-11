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
	
	Items.Label.Title = StringFunctions.FormattedString(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thực hiện đăng nhập vào cơ sở thông tin nhằm mục đích thử nghiệm tự động
			           |với tham số khởi động <b>%1</b>.
			           |
			           |Người sử dụng không nên làm việc ở chế độ này,
			           |bởi vì điều này sẽ gây xung đột hoặc mất dữ liệu.';
			           |ru = 'Вход в информационную базу был выполнен в целях автоматического тестирования
			           |с параметром запуска <b>%1</b>.
			           |
			           |Работа пользователей в этом режиме настоятельно не рекомендуется,
			           |так как это приведет к рассогласованию или потере данных.';
			           |en = 'The authorization in the infobase was performed for automated testing purposes,
			           |using the startup parameter <b>%1</b>.
			           |
			           |It is strongly recommended that you do not allow normal user operation in this mode
			           |as it will result in data losses or mismatches.'; fa = 'The authorization in the infobase was performed for automated testing purposes,
			           |using the startup parameter <b>%1</b>.
			           |
			           |It is strongly recommended that you do not allow normal user operation in this mode
			           |as it will result in data losses or mismatches.';
			           |it = 'Вход в информационную базу был выполнен в целях автоматического тестирования
			           |с параметром запуска <b>%1</b>.
			           |
			           |Работа пользователей в этом режиме настоятельно не рекомендуется,
			           |так как это приведет к рассогласованию или потере данных.';
			           |pl = 'The authorization in the infobase was performed for automated testing purposes,
			           |using the startup parameter <b>%1</b>.
			           |
			           |It is strongly recommended that you do not allow normal user operation in this mode
			           |as it will result in data losses or mismatches.';
			           |tr = 'Başlatma parametresiyle otomatik test amacıyla 
			           |infobase''e giriş yapıldı <b>%1</b>.
			           |
			           |Tutarsızlığa veya veri kaybına neden olacağından,
			           | kullanıcıların bu modda çalışması kesinlikle önerilmez.'"),
			"DisableSystemStartupLogic"));
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not StandardSubsystemsClient.ApplicationStartupLogicDisabled() Then
		Return;
	EndIf;
	
	Items.TestMode.Visible = True;
	
	TestModeTitle = "{" + NStr("vi = 'Thử nghiệm';
								|ru = 'Тестирование';
								|en = 'Testing'; fa = 'آزمون';
								|it = 'Testing';
								|pl = 'Testowanie';
								|tr = 'Test'") + "} ";
	CurrentTitle = ClientApplication.GetCaption();
	
	If StrStartsWith(CurrentTitle, TestModeTitle) Then
		Return;
	EndIf;
	
	ClientApplication.SetCaption(TestModeTitle + CurrentTitle);
	
	RegisterApplicationStartupLogicDisabling();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RegisterApplicationStartupLogicDisabling()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataOwner = Catalogs.MetadataObjectIDs.GetRef(
		New UUID("627a6fb8-872a-11e3-bb87-005056c00008")); // Constants.
	
	DisablingDates = Common.ReadDataFromSecureStorage(DataOwner); // Array
	If TypeOf(DisablingDates) <> Type("Array") Then
		DisablingDates = New Array;
	EndIf;
	
	DisablingDates.Add(CurrentSessionDate());
	Common.WriteDataToSecureStorage(DataOwner, DisablingDates);
	
EndProcedure

#EndRegion
