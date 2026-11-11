
#Region FormTableItemsEventHandlersRegisteredRecordsOfAvailabilityOfWorkCenterTypes

&AtClient
Procedure RegisteredRecordsOfAvailabilityOfWorkCenterTypesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.RegisteredRecordsOfAvailabilityOfWorkCenterTypes.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "WorkCenterType"
		And ValueIsFilled(CurrentData.WorkCenterType) Then
		ShowValue(, CurrentData.WorkCenterType);
	ElsIf Field.Name = "ReferenceOrder"
		And ValueIsFilled(CurrentData.ReferenceOrder) Then
		ShowValue(, CurrentData.ReferenceOrder);
	ElsIf Field.Name = "Stage"
		And ValueIsFilled(CurrentData.Stage) Then
		ShowValue(, CurrentData.Stage);
	ElsIf Field.Name = "Department"
		And ValueIsFilled(CurrentData.Department) Then
		ShowValue(, CurrentData.Department);
	ElsIf Field.Name = "Shift"
		And ValueIsFilled(CurrentData.Shift) Then
		ShowValue(, CurrentData.Shift);
	ElsIf Field.Name = "SetupSettings"
		And ValueIsFilled(CurrentData.SetupSettings) Then
		ShowValue(, CurrentData.SetupSettings);
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
