
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = NStr("vi = 'Hướng dẫn tùy chỉnh ứng dụng di động ""%1""';
				|ru = 'Инструкция по настройке мобильного приложения ""%1""';
				|en = '%1 mobile application setup instruction'; fa = '%1 mobile application setup instruction';
				|it = 'Istruzioni per le impostazioni dell''app mobile ""%1""';
				|pl = 'Instrukcja konfiguracji aplikacji mobilnej ""%1""';
				|tr = '""%1"" mobil uygulama ayarları talimatı'");
	Title = StringFunctionsClientServer.SubstituteParametersToString(Title, Parameters.ApplicationName_2);
	
	TemplateDescriptionOfApplication = Metadata.CommonTemplates.Find(Parameters.DescriptionLayoutName);
	If TemplateDescriptionOfApplication <> Undefined Then
		ApplicationDescription = GetCommonTemplate(TemplateDescriptionOfApplication).GetText();
	EndIf;
EndProcedure

#EndRegion
