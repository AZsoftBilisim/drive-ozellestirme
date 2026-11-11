#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers		
		
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Settings = SettingsComposer.GetSettings();
	
	TitleAutomatically = NStr("vi = '<Tự động>';
								|ru = '<Автоматически>';
								|en = '<Automatically>'; fa = '<Automatically>';
								|it = '<Automaticamente>';
								|pl = '<Automatycznie>';
								|tr = '<Otomatik olarak>'");
	Settings.DataParameters.SetParameterValue("TitleAutomatically", TitleAutomatically);
	
	SettingsComposer.LoadSettings(Settings);
	
EndProcedure

#EndRegion

#EndIf