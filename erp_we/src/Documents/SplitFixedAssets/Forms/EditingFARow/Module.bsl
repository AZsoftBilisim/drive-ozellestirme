
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AttributesToSave    = Parameters.AttributesToSave;
	BusinessOperation   = Parameters.BusinessOperation;
	Organization             = Parameters.Organization;
	RecordInManAccounting       = Parameters.RecordInManAccounting;
	RecordInLocalAccounting      = Parameters.RecordInLocalAccounting;
	Date                    = Parameters.Date;
	ListOfFA.LoadValues(Parameters.ListOfFA);

	CurrencyOfMan  = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	If Parameters.Property("AttributesValues") Then
	
		FillPropertyValues(ThisObject, Parameters.AttributesValues);
	
	EndIf;
	
	OnReadCreateAtServer();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Modified Then
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
				|ru = 'Данные были изменены. Сохранить изменения?';
				|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
				|it = 'I dati sono stati modificati. Salvare le modifiche?';
				|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AuxiliaryAttributes = Documents.SplitFixedAssets.AuxiliaryAttributes(ThisObject);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FADisassembly(
									ThisObject, AuxiliaryAttributes);
	
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FixedAssetOnChange(Item)

	MainRemedyWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CostInAccountingOnChange(Item)
	
	If RecordInManAccounting Then
		
		CostUU_New = ?(CostInAccounting <> 0, CostInManagementAccounting * FAAttributeValuesBeforeChange.CostInAccounting / CostInAccounting, 0);
		CostUU_New = Round(CostUU_New, FormServiceParameters.FractionDigits); 
			
		If CostInManagementAccounting = CostUU_New Then
			
			CostUU_New = ?(CostInAccounting <> 0, CostInManagementAccounting * CostInAccounting / CostInAccounting, 0);
			CostUU_New = Round(CostUU_New, FormServiceParameters.FractionDigits); 
			CostInManagementAccounting = CostUU_New;
			
		EndIf; 
		
	EndIf;
	
	SplitFixedAssetsClientLocalization.FACostInAccountingOnChange(ThisObject, ThisObject);
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure CostInTaxAccountingOnChange(Item)
	
	CostTemporaryDifference = CostInAccounting - CostInTaxAccounting - CostPermanentDifference;
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure CostPermanentDifferenceOnChange(Item)
	
	CostTemporaryDifference = CostInAccounting - CostInTaxAccounting - CostPermanentDifference;
	
EndProcedure

&AtClient
Procedure CostInManagementAccountingOnChange(Item)
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtClient
Procedure DepreciationMethodAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("DepreciationMethodAccounting");
	
EndProcedure

&AtClient
Procedure UsefulLifeAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("UsefulLifeAccounting");
	
EndProcedure

&AtClient
Procedure DepreciationAccrualMethodManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("DepreciationAccrualMethodManagementAccounting");
	
EndProcedure

&AtClient
Procedure UsefulLifeManagementAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("UsefulLifeManagementAccounting");
	
EndProcedure

&AtClient
Procedure RunningTimeValueOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("RunningTimeValue");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowPD(Command)

	Items.FormShowPD.Check = Not Items.FormShowPD.Check;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Command.Name);
		
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	If Parameters.NewRow And Not Parameters.Copy Then
		FillInDefaultValues();
	EndIf;
	
	InitializeServiceParametersOfForm();
	
	Items.LiquidationValueCurrency.Title = CurrencyOfMan;
	Items.LiquidationValueReglCurrency.Title = ComplCurrency;
	
	SplitFixedAssetsLocalization.FormForEditingOS_StringWhenReadingFileOnServer(ThisObject);
	
	FillInFADetails();
	
	ConfigureDependentFormElementsOnServer();
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDefaultValues()

	AuxiliaryAttributes = Documents.SplitFixedAssets.AuxiliaryAttributes(ThisObject);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FADisassembly(
									ThisObject, AuxiliaryAttributes, "");
									
	Documents.SplitFixedAssets.FillInDetailsDependingOnProperties(
			ThisObject, AuxiliaryAttributes, ItemDetailsParameters);
										
	Documents.SplitFixedAssets.FillInDefaultValues(ThisObject, ThisObject);
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	InternalParameters = New Structure;
	InternalParameters.Insert("AttributesThatShouldMatch", "Organization,Department,LineOfBusiness");
	InternalParameters.Insert("FractionDigits", TMCommonUse.BitDepthOfMoneyField(AllowedSign.Nonnegative).FractionDigits);
	InternalParameters.Insert("FractionDigits", TMCommonUse.BitDepthOfMoneyField(AllowedSign.Nonnegative).FractionDigits);
	
	InternalParameters.Insert(
		"FSB6IsApplied",
		AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate()))));

	SplitFixedAssetsLocalization.AddServiceParametersToForm(InternalParameters);
	
	FormServiceParameters = New FixedStructure(InternalParameters);
	
	FillInDetailsValuesBeforeChange(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInFADetails()

	If Not ValueIsFilled(FixedAsset) Then
		FAInformation = New FormattedString("");
		Return;
	EndIf; 
	
	ReceivedDetails = New Structure;
	ReceivedDetails.Insert("AssetID");
	FAAttributes = Common.ObjectAttributesValues(FixedAsset, ReceivedDetails);
	
	StringsList = New Array;
	
	StringsList.Add(NStr("vi = 'Số kiểm kê:';
						|ru = 'Инв. №:';
						|en = 'Inv. No.'; fa = 'شماره اموال';
						|it = 'N. d''inventario:';
						|pl = 'Nr inwentarzowy:';
						|tr = 'Env. No.:'"));
	If ValueIsFilled(FAAttributes.AssetID) Then
		StringsList.Add(" ");
		StringsList.Add(TrimAll(FAAttributes.AssetID));
	Else	
		StringsList.Add(" ");
		RowData = New FormattedString(NStr("vi = 'chưa điền';
											|ru = 'не заполнен';
											|en = 'not filled in'; fa = 'not filled in';
											|it = 'non compilato';
											|pl = 'nie wypełniony';
											|tr = 'doldurulmadı'"),, StyleColors.GrayTextColor1);
		StringsList.Add(RowData);
	EndIf;	
	
	FAInformation = New FormattedString(StringsList);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		AuxiliaryAttributes = Documents.SplitFixedAssets.AuxiliaryAttributes(ThisObject);
		
		ValueIsVisible = Common.ObjectAttributeValue(FixedAsset, "OSType") <> PredefinedValue("Enum.FATypes.DepreciationComponent");
		
		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.DepreciationAccrualMethodManagementAccounting.ChoiceList, 
			ValueIsVisible, 
			PredefinedValue("Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction"));

	EndIf;
	
	If UpdateAll Then
		
		ReglRecordsAreMaintained = LocalAccntingServer.ReglRecordsAreMaintained(Date);

		Items.UuDepreciationGroup.ShowTitle = RecordInManAccounting And (RecordInManAccounting And RecordInLocalAccounting);
		
		If AuxiliaryAttributes.ComplianceCAAccountingIsKept Then
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'KTQT (%1):';
															|ru = 'УУ (%1):';
															|en = 'MA (%1):'; fa = 'MA (%1):';
															|it = 'Contabilità Gestionale (%1):';
															|pl = 'EZ (%1):';
															|tr = 'Yönetim Muhasebesi(%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'KTDN (%1):';
																|ru = 'БУ (%1):';
																|en = 'LA (%1):'; fa = 'LA (%1):';
																|it = 'Contabilità (%1):';
																|pl = 'EK (%1):';
																|tr = 'Genel Muhasebe (%1):'"), String(ComplCurrency));
		Else
			Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
															|ru = 'Упр. (%1):';
															|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
															|it = 'Gest. (%1):';
															|pl = 'Zarz. (%1):';
															|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
			Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'Tài chính (%1):';
																|ru = 'Регл. (%1):';
																|en = 'Local (%1):'; fa = 'Local (%1):';
																|it = 'Regol. (%1):';
																|pl = 'Reg. (%1):';
																|tr = 'Yerel (%1):'"), String(ComplCurrency));
		EndIf; 
		
		Items.DecorationTitleVR.Visible = False;
		Items.DecorationTitlePR.Visible = False;
		Items.DecorationTitleWELL.Visible = False;
		Items.DecorationRateOfDepreciationBurien.Visible = False;
		
		FillInFASelectionParameters();
		

	EndIf;

	SplitFixedAssetsLocalization.FormEditStringOS_ConfigureDependentFormElements(
		ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")

	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure(Form.AuxiliaryAttributes);
	AuxiliaryAttributes.Insert("ShowPD", Items.FormShowPD.Check);
	AuxiliaryAttributes.Insert("FSB6IsApplied", FormServiceParameters.FSB6IsApplied);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_FADisassembly(
									Form, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Form, ItemDetailsParameters);
	EndIf;
	
	If UpdateAll Then
		
		Items.LiquidationValueReglCurrency.Visible = Items.ResidualValueLocal.Visible;
		Items.LiquidationValueCurrency.Visible = Items.ResidualValueMan.Visible;
		
		Items.GroupDepreciation.Visible = 
			Form.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
			
		Items.GroupGeneral.Visible = 
			Form.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
	
	EndIf;
	
	Items.DecorationTitleUU.Visible = Items.CostInManagementAccounting.Visible;
	Items.DecorationTitleBOO.Visible = Items.CostInAccounting.Visible;
	
	If StructureOfChangedProps.Property("UsefulLifeManagementAccounting")
		Or UpdateAll Then
		
		Form.UsefulLifeMAExplanation = NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(
			Form.UsefulLifeManagementAccounting);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RunningTimeValue")
		Or UpdateAll Then
			
		If ValueIsFilled(Form.RunningTimeValue) Then
			Items.EstimatedRunningTime.ToolTip = UnitOfMeasurementOfOperatingTimeIndicator(Form.RunningTimeValue);
		Else
			Items.EstimatedRunningTime.ToolTip = "";
		EndIf; 
		
	EndIf;
	
	
	FillInDetailsValuesBeforeChange(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsValuesBeforeChange(Form)

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("CostInManagementAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInTaxAccounting", 0);

	FillPropertyValues(AttributesValuesBeforeChange, Form);
	
	Form.FAAttributeValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure FillInFASelectionParameters(ParameterValues = Undefined)

	If ParameterValues = Undefined Then
		ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssets(ThisObject);
		ParameterValues = ParametersForSelectingFixedAssets.ParameterValues;
	EndIf;
	
	ListOfTSSelectionParameters = New Array;
	
	StateNotAccepted = New Array;
	StateNotAccepted.Add(Enums.FixedAssetsStates.NotRecognized_);
	StateNotAccepted.Add(Enums.FixedAssetsStates.TakenOffBooks);
	ChoiceParameter = New ChoiceParameter("Filter.State", StateNotAccepted);
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	
	ChoiceParameter = New ChoiceParameter("Context", "ACC,MA");
	ListOfTSSelectionParameters.Add(ChoiceParameter);
	
	If ParameterValues <> Undefined Then
		
		For Each FASelectionParameter In ParameterValues Do
			ChoiceParameter = New ChoiceParameter("Filter." + FASelectionParameter.Key, FASelectionParameter.Value);
			ListOfTSSelectionParameters.Add(ChoiceParameter);
		EndDo;
		
	Else
		
		// In the document, the OS is also selected, according to which you can immediately determine the selection.
		// Therefore, in the selection form, you need to check the matching of the details as you select.
		ChoiceParameter = New ChoiceParameter("AttributesThatShouldMatch", FormServiceParameters.AttributesThatShouldMatch);
		ListOfTSSelectionParameters.Add(ChoiceParameter);
		
	EndIf;
	
	ThisIsAllocationOfComponentNodes = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
	
	ArrayOfFATypes = New Array;
	If ThisIsAllocationOfComponentNodes Then
	
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Node"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.DepreciationComponent"));
	
	Else
	
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
	
	EndIf;
	
	ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));
	ListOfTSSelectionParameters.Add(ChoiceParameter);
		
	Items.FixedAsset.ChoiceParameters = New FixedArray(ListOfTSSelectionParameters);

EndProcedure

&AtClientAtServerNoContext
Function ParametersForSelectingFixedAssets(Object)

	ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssetsOnServer(Object.FixedAsset,
		Object.ListOfFA.UnloadValues(), Object.Date);

	Return ParametersForSelectingFixedAssets;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingFixedAssetsOnServer(Val FixedAsset, Val ListOfFA, Val Date)

	Return Documents.SplitFixedAssets.CheckSelectionOfFixedAssets(FixedAsset, ListOfFA, Date);

EndFunction

&AtServerNoContext
Function UnitOfMeasurementOfOperatingTimeIndicator(Val RunningTimeValue)

	Return Common.ObjectAttributeValue(RunningTimeValue, "UnitOfMeasure");

EndFunction

&AtServer
Procedure MainRemedyWhenChangingOnServer()

	FillInFADetails();
	
	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()

	ClearMessages();
	
	If Not CheckFilling() Then
		QueryText = NStr("vi = 'Chưa điền trường bắt buộc.
                             |Có thể kết thúc chỉnh sửa hoặc tiếp tục chỉnh sửa.';
                             |ru = 'Не заполнены обязательные поля.
                             |Можно завершить редактирование или продолжить редактирование.';
                             |en = 'Some of the required fields are not filled in.
                             |You can choose to finish editing or continue.'; fa = 'Some of the required fields are not filled in.
                             |You can choose to finish editing or continue.';
                             |it = 'I campi obbligatori non sono stati compilati. 
                             |E'' possibile terminare o continuare la compilazione.';
                             |pl = 'Nie wypełnione wymagane pola.
                             |Można zakończyć edycję lub kontynuować edycję.';
                             |tr = 'Gerekli alanlar doldurulmamıştır. 
                             |Düzenlemeyi bitirebilir veya düzenlemeye devam edebilirsiniz.'");
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết thúc soạn';
													|ru = 'Завершить редактирование';
													|en = 'Finish editing'; fa = 'پایان ویرایش';
													|it = 'Terminare la modifica';
													|pl = 'Zakończ edycję';
													|tr = 'Düzenlemeyi bitir'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục chỉnh sửa';
													|ru = 'Продолжить редактирование';
													|en = 'Continue editing'; fa = 'Continue editing';
													|it = 'Continuare le modifiche';
													|pl = 'Kontynuuj edycję';
													|tr = 'Düzenlemeye devam et'"));
		CallbackDescription = New CallbackDescription("CompleteEditingCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	Else
		CompleteEditingCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 

EndProcedure

&AtClient
Procedure CompleteEditingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	EditResult = New Structure(AttributesToSave);
	FillPropertyValues(EditResult, ThisObject);
	
	Modified = False;
	
	Close(EditResult);
	
EndProcedure

#EndRegion
