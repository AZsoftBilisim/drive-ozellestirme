
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
	
	Parameters.Property("ActionType", ActionType);
	If ActionType = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm Then
		Items.BudgetProfilesAction.Visible = False;
		Items.BudgetProfilesCalculationRule.Visible = False;
		Items.BudgetProfilesPeriodicity.Visible = False;
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		Items.BudgetProfilesBudgetProfile.Visible = False;
		Items.BudgetProfilesBudgetProfilePeriodicity.Visible = False;
		Items.BudgetProfilesAction.Visible = False;
		Title = NStr("vi = 'Tùy chỉnh tạo phát sinh ngân sách theo quy tắc tính toán';
					|ru = 'Настройки формирования оборотов бюджетов по правилам расчета';
					|en = 'Budget turnover settings according to the calculation rules'; fa = 'Budget turnover settings according to the calculation rules';
					|it = 'Budget turnover settings according to the calculation rules';
					|pl = 'Budget turnover settings according to the calculation rules';
					|tr = 'Hesaplama kurallarına göre bütçe cirolarının oluşturma ayarları'");
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets Then
		Items.BudgetProfilesCalculationRule.Visible = False;
		Items.BudgetProfilesPeriodicity.Visible = False;
		Title = NStr("vi = 'Tùy chỉnh điều chỉnh/chỉnh sửa ngân sách';
					|ru = 'Настройки корректировки/исправления бюджетов';
					|en = 'Customization of budget adjustment/correction'; fa = 'Customization of budget adjustment/correction';
					|it = 'Настройки корректировки/исправления бюджетов';
					|pl = 'Customization of budget adjustment/correction';
					|tr = 'Bütçe değiştirme/düzeltme ayarları'");
	EndIf;
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetProfiles

&AtClient
Procedure BudgetProfilesOnChange(Item)
	
	For Each BudgetLine In BudgetProfiles Do
		BudgetLine.LineNumber = BudgetProfiles.IndexOf(BudgetLine) + 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure BudgetProfilesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Items.BudgetProfiles.CurrentData.RowKey = New UUID();
	EndIf;

EndProcedure

&AtClient
Procedure BudgetProfilesBeforeDeleteRow(Item, Cancel)
	
	DimensionSettingLineKey = Items.BudgetProfiles.CurrentData.DimensionSettingLineKey;
	DeleteAnalyticsSettings(DimensionSettingLineKey);
	
EndProcedure

&AtClient
Procedure BudgetProfilesMeasurementRepresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	
	ChoiceList = BudgetViewSettings(CurrentData);
	
	CallbackDescription = New CallbackDescription("TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion", ThisObject);
	ShowChooseFromList(CallbackDescription,ChoiceList,Item,
		ChoiceList.FindByValue(CurrentData.DimensionSettingLineKey));

EndProcedure

&AtClient
Procedure TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined Then
		CurrentData = Items.BudgetProfiles.CurrentData;
		
		ValueSelected = SelectionResult.Value;
		
		If Not ValueIsFilled(ValueSelected) Or ValueSelected = CurrentData.RowKey Then
			CurBudget = CurrentData.BudgetProfile;
			DimensionSettingLineKey = ValueSelected;
			If Not ValueIsFilled(DimensionSettingLineKey) Then
				DimensionSettingLineKey = Items.BudgetProfiles.CurrentData.RowKey; 
			EndIf;
				
			AddressBudgetPopulationDimension = CommitBudgetFillAnalystIntoStorage();

			FormParameters = New Structure();
			FormParameters.Insert("AddressBudgetPopulationDimension", AddressBudgetPopulationDimension);
			FormParameters.Insert("RowKey", DimensionSettingLineKey);
			FormParameters.Insert("BudgetProfile", CurBudget);
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
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	If CurrentData.RowKey = CurrentData.DimensionSettingLineKey Then
		SelectionResult = New Structure();
		SelectionResult.Insert("Value", CurrentData.DimensionSettingLineKey);
		SelectionResult.Insert("Presentation", NStr("vi = 'Tùy chỉnh cá nhân';
													|ru = 'Индивидуальные настройки';
													|en = 'Individual settings'; fa = 'Individual settings';
													|it = 'Impostazioni individuali';
													|pl = 'Indywidualne ustawienia';
													|tr = 'Kişisel ayarlar'"));
		TypesOfBudgetsPresentationOfMeasurementsSelectionCompletion(SelectionResult, Undefined)
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetProfilesMeasurementRepresentationClearing(Item, StandardProcessing)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
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
	FoundRows = BudgetProfiles.FindRows(FilterParameters);
	If FoundRows.Count() > 0 Then
		FoundRows[0].DimensionSettingLineKey = DimensionSettingLineKey;
		FoundRows[0].MeasurementRepresentation = NStr("vi = 'Tùy chỉnh cá nhân';
														|ru = 'Индивидуальные настройки';
														|en = 'Individual settings'; fa = 'Individual settings';
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
	
	For Each Page1 In BudgetProfiles Do
		If Page1.RowKey <> CurrentData.RowKey And Page1.RowKey = Page1.DimensionSettingLineKey Then
			SettingPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tương tự như %1. %2';
					|ru = 'Аналогично с.%1%2';
					|en = 'Similar to .%1.%2'; fa = 'Similar to .%1.%2';
					|it = 'Analogicamente con.%1%2';
					|pl = 'Analogicznie z.%1%2';
					|tr = 'Benzer şekilde %1 ile.%2'"),
				Page1.LineNumber,
				Page1.BudgetProfile);	
			SettingsList.Add(Page1.DimensionSettingLineKey, SettingPresentation);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(CurrentData.DimensionSettingLineKey)
		Or CurrentData.RowKey = CurrentData.DimensionSettingLineKey Then
		SettingPresentation = NStr("vi = 'Tùy chỉnh cá nhân';
									|ru = 'Индивидуальные настройки';
									|en = 'Individual settings'; fa = 'Individual settings';
									|it = 'Impostazioni individuali';
									|pl = 'Indywidualne ustawienia';
									|tr = 'Kişisel ayarlar'");	
		SettingsList.Add(CurrentData.DimensionSettingLineKey, SettingPresentation);
	ElsIf ValueIsFilled(CurrentData.DimensionSettingLineKey)
		And CurrentData.RowKey <> CurrentData.DimensionSettingLineKey Then
		SettingPresentation = NStr("vi = 'Tùy chỉnh cá nhân';
									|ru = 'Индивидуальные настройки';
									|en = 'Individual settings'; fa = 'Individual settings';
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
	
	For Each Page1 In BudgetProfiles Do
		
		Cnt = BudgetProfiles.IndexOf(Page1);
		
		If ActionType = PredefinedValue(
			"Enum.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules") Then
			If Not ValueIsFilled(Page1.CalculationRule) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong dòng %1 chưa điền quy tắc tính toán';
						|ru = 'В строке %1 не заполнено правило расчета';
						|en = 'Calculation rule in line %1 is not filled in'; fa = 'Calculation rule in line %1 is not filled in';
						|it = 'Calculation rule in line %1 is not filled in';
						|pl = 'Calculation rule in line %1 is not filled in';
						|tr = '%1 satırda hesaplama kuralı doldurulmamış'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetProfiles[%1].CalculationRule",
					Cnt);
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
			If Not ValueIsFilled(Page1.Periodicity) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong dòng %1 chưa điền tính định kỳ';
						|ru = 'В строке %1 не заполнена периодичность';
						|en = 'Frequency in line %1 is not filled in'; fa = 'Frequency in line %1 is not filled in';
						|it = 'Frequency in line %1 is not filled in';
						|pl = 'Frequency in line %1 is not filled in';
						|tr = '%1 satırda sıklık doldurulmamış'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetProfiles[%1].Periodicity",
					Cnt);
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
		Else
			If Not ValueIsFilled(Page1.BudgetProfile) Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền dạng ngân sách trong dòng %1';
						|ru = 'В строке %1 не заполнен вид бюджета';
						|en = 'Budget profile in line %1 is not filled in'; fa = 'Budget profile in line %1 is not filled in';
						|it = 'Nella riga %1 non è compilato il tipo di budget';
						|pl = 'W wierszu %1 nie jest wypełniony rodzaj budżetu';
						|tr = 'Satır %1''de bütçe profili doldurulmamış'"),
					Cnt+1);
				DataPath = StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetProfiles[%1].BudgetProfile",
					Cnt);
				CommonClient.MessageToUser(MessageText,,, DataPath, Cancel);
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Page1.MeasurementRepresentation) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền tùy chỉnh đo lường trong dòng %1';
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
	
	FoundRows = BudgetProfiles.FindRows(FilterParameters);
	
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
