
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Object.ThisIsTemplateGroup = True;
	
	If Not ValueIsFilled(Parameters.Key) Then
		Title = NStr("vi = 'Khuôn mẫu bút toán (Tạo nhóm)';
					|ru = 'Шаблоны проводок (Создание группы)';
					|en = 'Posting templates (Group creation)'; fa = 'Posting templates (Group creation)';
					|it = 'Modelli voci di registro (creazione gruppo)';
					|pl = 'Szablony dekretowań (Tworzenie grupy)';
					|tr = 'Giriş şablonu (Grup oluşturulması)'");
		AutoTitle = False;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Key) Or ValueIsFilled(Parameters.CopyingValue) Then
		Catalogs.PostingTemplatesForFinancialAccounting.InitializeComposer(ThisObject, Object.Operation);
	EndIf;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		SavedSettings = Common.ObjectAttributeValue(Parameters.CopyingValue, "AdditionalSelection").Get();
		Catalogs.PostingTemplatesForFinancialAccounting.LoadSettings(ThisObject, SavedSettings);
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	Catalogs.PostingTemplatesForFinancialAccounting.RecordAdditionalSelection(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	Catalogs.PostingTemplatesForFinancialAccounting.InitializeComposer(ThisObject, CurrentObject.Operation);
	
	SavedSettings = CurrentObject.AdditionalSelection.Get();
	Catalogs.PostingTemplatesForFinancialAccounting.LoadSettings(ThisObject, SavedSettings);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Title = "";
	AutoTitle = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
