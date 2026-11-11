
#Region FormEventHandlers

&AtClient
Procedure OnClose()
	
	Notify("ChangingSettings_ContactInformationReport",String(Report.SettingsComposer.Settings.Filter),ThisForm);
	
EndProcedure

#EndRegion

