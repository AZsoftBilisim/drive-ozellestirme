
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DisplayRowCode   = Parameters.DisplayRowCode;
	DisplayNoteInReport  = Parameters.DisplayNoteInReport;
	RowCodeHeader = Parameters.RowCodeHeader;
	CommentHeader = Parameters.CommentHeader;
	ReportLanguage          = Parameters.ReportLanguage;
	ReadOnly      = Parameters.ReadOnly;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ReportLanguageStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = GetLanguageCodes(); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ReportSettings = New Structure;
	ReportSettings.Insert("DisplayRowCode",   DisplayRowCode);
	ReportSettings.Insert("DisplayNoteInReport",  DisplayNoteInReport);
	ReportSettings.Insert("RowCodeHeader", RowCodeHeader);
	ReportSettings.Insert("CommentHeader", CommentHeader);
	ReportSettings.Insert("ReportLanguage",          ReportLanguage);
	
	Close(ReportSettings);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function GetLanguageCodes()
	
	LanguagesCodes = New ValueList; 
	InternationalReportingClientLocalization.ListOfReportingLanguages(LanguagesCodes);
	
	LanguagesCodes.Add("en", NStr("vi = 'Tiếng Anh';
									|ru = 'Английский';
									|en = 'English'; fa = 'انگلیسی';
									|it = 'Inglese';
									|pl = 'English';
									|tr = 'İngilizce'"));
	LanguagesCodes.Add("ru", NStr("vi = 'Tiếng Nga';
									|ru = 'Русский';
									|en = 'Russian'; fa = 'روسی';
									|it = 'Russo';
									|pl = 'Russian';
									|tr = 'Rusça'"));
	
	Return LanguagesCodes; 
	
EndFunction

#EndRegion