#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);

	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion
	
#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineOther_", NStr("vi = 'Phần khác';
																					|ru = 'Прочие';
																					|en = 'Other'; fa = 'سایر';
																					|it = 'Altri';
																					|pl = 'Other';
																					|tr = 'Diğer'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StringSatisfied", NStr("vi = 'Hài lòng';
																						|ru = 'Удовлетворено';
																						|en = 'Fulfilled'; fa = 'انجام‌شده';
																						|it = 'Soddisfatto';
																						|pl = 'Zadowolono';
																						|tr = 'Karşılandı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StringNotSatisfied", NStr("vi = 'Không hài lòng';
																							|ru = 'Не удовлетворено';
																							|en = 'Not fulfilled'; fa = 'اجرا نشده';
																							|it = 'Non soddisfatto';
																							|pl = 'Nie spełniono';
																							|tr = 'Karşılanmadı'"));
EndProcedure

#EndRegion 

#EndIf