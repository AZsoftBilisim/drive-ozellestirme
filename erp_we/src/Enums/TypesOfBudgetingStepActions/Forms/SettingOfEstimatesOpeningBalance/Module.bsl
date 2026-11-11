
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingModel = Parameters.BudgetingModel;
	
	ActionSettings = GetFromTempStorage(Address);

	Enums.TypesOfBudgetingStepActions.RestoreActionSettings(ActionSettings, ThisObject);
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetProfiles

&AtClient
Procedure BudgetProfilesOnChange(Item)
	
	For Each BudgetLine In BalancesOfCalculatedIndicators Do
		BudgetLine.LineNumber = BalancesOfCalculatedIndicators.IndexOf(BudgetLine) + 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure BudgetProfilesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.BalancesOfCalculatedIndicators.CurrentData.RowKey = New UUID();
	EndIf;

EndProcedure

&AtClient
Procedure BudgetProfilesBeforeDeleteRow(Item, Cancel)
	
	DimensionSettingLineKey = Items.BalancesOfCalculatedIndicators.CurrentData.DimensionSettingLineKey;
	DeleteAnalyticsSettings(DimensionSettingLineKey);
	
EndProcedure

&AtClient
Procedure BudgetProfilesMeasurementRepresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.BalancesOfCalculatedIndicators.CurrentData;
	
	ChoiceList = BudgetViewSettings(CurrentData);
	
	CallbackDescription = New CallbackDescription("TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion", ThisObject);
	ShowChooseFromList(CallbackDescription,ChoiceList,Item,
		ChoiceList.FindByValue(CurrentData.DimensionSettingLineKey));

EndProcedure

&AtClient
Procedure TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined Then
		CurrentData = Items.BalancesOfCalculatedIndicators.CurrentData;
		
		ValueSelected = SelectionResult.Value;
		
		If Not ValueIsFilled(ValueSelected) Or ValueSelected = CurrentData.RowKey Then
			CurrentIndicator = CurrentData.BudgetBalanceItem;
			DimensionSettingLineKey = ValueSelected;
			If Not ValueIsFilled(DimensionSettingLineKey) Then
				DimensionSettingLineKey = Items.BalancesOfCalculatedIndicators.CurrentData.RowKey; 
			EndIf;
				
			AddressBudgetPopulationDimension = CommitBudgetFillAnalystIntoStorage();

			FormParameters = New Structure();
			FormParameters.Insert("AddressBudgetPopulationDimension", AddressBudgetPopulationDimension);
			FormParameters.Insert("RowKey", DimensionSettingLineKey);
			FormParameters.Insert("BudgetBalanceItem", CurrentIndicator);
			FormParameters.Insert("BudgetingModel", BudgetingModel);
			
			Notification = New CallbackDescription("WhenClosingBudgetAnalystSettingsForm", ThisObject);
			
			OpenForm("Enum.TypesOfBudgetingStepActions.Form.DefaultBudgetFillingSettings",
							FormParameters,,,,,Notification,FormWindowOpeningMode.LockOwnerWindow);
			
		Else
			If CurrentData.DimensionSettingLineKey <> ValueSelected Then
				DeleteAnalyticsSettings(CurrentData.DimensionSettingLineKey);
			EndIf;
			CurrentData.DimensionSettingLineKey = ValueSelected;
			CurrentData.MeasurementRepresentation = SelectionResult.Presentation;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetProfilesMeasurementRepresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.BalancesOfCalculatedIndicators.CurrentData;
	If CurrentData.RowKey = CurrentData.DimensionSettingLineKey Then
		SelectionResult = New Structure();
		SelectionResult.Insert("Value", CurrentData.DimensionSettingLineKey);
		SelectionResult.Insert("Presentation", NStr("vi = 'Tùy chỉnh cá nhân';
													|ru = 'Индивидуальные настройки';
													|en = 'Personal settings'; fa = 'تنظیمات شخصی';
													|it = 'Impostazioni individuali';
													|pl = 'Indywidualne ustawienia';
													|tr = 'Kişisel ayarlar'"));
		TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion(SelectionResult, Undefined)
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetProfilesMeasurementRepresentationClearing(Item, StandardProcessing)
	
	CurrentData = Items.BalancesOfCalculatedIndicators.CurrentData;
	DeleteAnalyticsSettings(CurrentData.DimensionSettingLineKey);
	CurrentData.DimensionSettingLineKey = Undefined;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	Cancel = False;
	HandlingFillVerificationOnClient(Cancel);
	
	If Not Cancel Then
		Close(SaveSettingsAtServer());
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function SaveSettingsAtServer()
	
	Settings = Enums.TypesOfBudgetingStepActions.ActionSettings(ThisObject);
	Return PutToTempStorage(Settings, Address);
	
EndFunction

&AtClient
Procedure WhenClosingBudgetAnalystSettingsForm(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AddressAnalyst = Result.Address;
	DimensionSettingLineKey = Result.DimensionSettingLineKey;
	
	FilterParameters = New Structure("RowKey",DimensionSettingLineKey);
	FoundRows = BalancesOfCalculatedIndicators.FindRows(FilterParameters);
	If FoundRows.Count() > 0 Then
		FoundRows[0].DimensionSettingLineKey = DimensionSettingLineKey;
		FoundRows[0].MeasurementRepresentation = NStr("vi = 'Tùy chỉnh cá nhân';
														|ru = 'Индивидуальные настройки';
														|en = 'Personal settings'; fa = 'تنظیمات شخصی';
														|it = 'Impostazioni individuali';
														|pl = 'Indywidualne ustawienia';
														|tr = 'Kişisel ayarlar'");
	EndIf;
	
	FillInSettingsAnalystFillInBudgetServer(AddressAnalyst);
	
EndProcedure

&AtServer
Procedure FillInSettingsAnalystFillInBudgetServer(Address)
	
	BudgetPopulationDimension.Load(GetFromTempStorage(Address));
	
EndProcedure

&AtServer
Function CommitBudgetFillAnalystIntoStorage()
	
	If ValueIsFilled(AddressBudgetPopulationDimension) Then
		AddressBudgetPopulationDimension = PutToTempStorage(BudgetPopulationDimension.Unload(), AddressBudgetPopulationDimension);
	Else
		AddressBudgetPopulationDimension = PutToTempStorage(BudgetPopulationDimension.Unload(), UUID);
	EndIf;
	
	Return AddressBudgetPopulationDimension;

EndFunction

&AtClient
Function BudgetViewSettings(CurrentData)
	
	SettingsList = New ValueList;
	
	For Each Page1 In BalancesOfCalculatedIndicators Do
		If Page1.RowKey <> CurrentData.RowKey And Page1.RowKey = Page1.DimensionSettingLineKey Then
			SettingPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tương tự như %1. %2';
					|ru = 'Аналогично с.%1%2';
					|en = 'Similar to .%1.%2'; fa = 'Similar to .%1.%2';
					|it = 'Analogicamente con.%1%2';
					|pl = 'Analogicznie z.%1%2';
					|tr = 'Benzer şekilde %1 ile.%2'"),
				Page1.LineNumber,
				Page1.BudgetBalanceItem);
			SettingsList.Add(Page1.DimensionSettingLineKey, SettingPresentation);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(CurrentData.DimensionSettingLineKey)
		Or CurrentData.RowKey = CurrentData.DimensionSettingLineKey Then
		SettingPresentation = NStr("vi = 'Tùy chỉnh cá nhân';
									|ru = 'Индивидуальные настройки';
									|en = 'Personal settings'; fa = 'تنظیمات شخصی';
									|it = 'Impostazioni individuali';
									|pl = 'Indywidualne ustawienia';
									|tr = 'Kişisel ayarlar'");	
		SettingsList.Add(CurrentData.DimensionSettingLineKey, SettingPresentation);
	ElsIf ValueIsFilled(CurrentData.DimensionSettingLineKey)
		And CurrentData.RowKey <> CurrentData.DimensionSettingLineKey Then
		SettingPresentation = NStr("vi = 'Tùy chỉnh cá nhân';
									|ru = 'Индивидуальные настройки';
									|en = 'Personal settings'; fa = 'تنظیمات شخصی';
									|it = 'Impostazioni individuali';
									|pl = 'Indywidualne ustawienia';
									|tr = 'Kişisel ayarlar'");
		SettingsList.Add(CurrentData.RowKey, SettingPresentation);
	EndIf;
	
	Return SettingsList;

EndFunction

&AtClient
Procedure HandlingFillVerificationOnClient(Cancel)
	
	ClearMessages();
	
	For Each Page1 In BalancesOfCalculatedIndicators Do
		
		Cnt = BalancesOfCalculatedIndicators.IndexOf(Page1);
		
		If Not ValueIsFilled(Page1.BudgetBalanceItem) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 chưa điền chỉ tiêu tính toán của ngân sách';
					|ru = 'В строке %1 не заполнен расчетный показатель бюджетов';
					|en = 'The estimated budget balance item is not filled in line %1.'; fa = 'The estimated budget balance item is not filled in line %1.';
					|it = 'The estimated budget balance item is not filled in line %1.';
					|pl = 'The estimated budget balance item is not filled in line %1.';
					|tr = '%1 satırında hesaplanan bütçe göstergesi doldurulmamış'"),
				Cnt+1);
			DataPath = StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetProfiles[%1].BudgetBalanceItem",
				Cnt);
			CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
		EndIf;
		
		If Not ValueIsFilled(Page1.MeasurementRepresentation) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 chưa điền tùy chỉnh chiều đo';
					|ru = 'В строке %1 не заполнены настройки измерений';
					|en = 'Dimension settings in line %1 are not filled in'; fa = 'Dimension settings in line %1 are not filled in';
					|it = 'Nella riga %1 non sono compilate le impostazioni di rilevamento';
					|pl = 'W wierszu %1 nie są wypełnione ustawienia pomiarów';
					|tr = 'Satır %1''de ölçü ayarları doldurulmamış'"),
				Cnt+1);
			DataPath = StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetProfiles[%1].MeasurementRepresentation",
				Cnt); 	
			CommonClient.MessageToUser(MessageText,,, DataPath,Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeleteAnalyticsSettings(DimensionSettingLineKey)
	
	FilterParameters = New Structure("DimensionSettingLineKey", DimensionSettingLineKey);
	
	FoundRows = BalancesOfCalculatedIndicators.FindRows(FilterParameters);
	
	If FoundRows.Count() <= 1 Then
		FilterParameters = New Structure("RowKey", DimensionSettingLineKey);
		FoundRows = BudgetPopulationDimension.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			For Each ItemToRemove In FoundRows Do
				BudgetPopulationDimension.Delete(ItemToRemove);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
