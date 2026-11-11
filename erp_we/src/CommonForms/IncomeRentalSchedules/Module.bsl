#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Date = Parameters.LeaseStartDate;
	Leaseholder = Parameters.Leaseholder;
	Contract = Parameters.Contract;
	FixedAsset = Parameters.FixedAsset;
	FormServiceParameters = Common.CopyRecursive(Parameters.FormServiceParameters, True);
	VATRate = FormServiceParameters.ContractDetails_.VATRate;
	Ref = Parameters.Ref;
	DisplayGraphOfPercentagesFromRegister = Parameters.DisplayGraphOfPercentagesFromRegister;
	
	DocumentCurrencyPresentation = FormServiceParameters.ContractDetails_.ARAPCurrencyPresentation;
	
	UploadCharts(Parameters.ContractSchedules);
	
	If TypeOf(Ref) <> Type("DocumentRef.EnterRentalInvestmentBalance") Then
		FAStrings = FATable.FindRows(New Structure("FixedAsset", FixedAsset));
		For Each FAString In FAStrings Do
			TheInterestAccrualScheduleIsEnteredManually = FAString.TheInterestAccrualScheduleIsEnteredManually;
		EndDo;
	Else
		TheInterestAccrualScheduleIsEnteredManually = True;
	EndIf;
	
	FillInSelectionsLabel();
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	LeasedAssetAccounting.CheckSchedule(
		ServicePaymentSchedule, 
		"ServicePaymentSchedule", 
		"RentalService", 
		Cancel);
		
	LeasedAssetAccounting.CheckSchedule(
		ServiceAccrualSchedule, 
		"ServiceAccrualSchedule", 
		"RentalService", 
		Cancel);

	LeasedAssetAccounting.CheckSchedule(
		InterestAccrualSchedule, 
		"InterestAccrualSchedule", 
		"Interests", 
		Cancel);
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheInterestAccrualScheduleIsEnteredManuallyOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);
	
	FAStrings = FATable.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each FAString In FAStrings Do
		FAString.TheInterestAccrualScheduleIsEnteredManually = TheInterestAccrualScheduleIsEnteredManually;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServicePaymentSchedule

&AtClient
Procedure ServicePaymentScheduleOnChange(Item)
	UpdateTotals(ThisObject);
EndProcedure

&AtClient
Procedure ServicePaymentScheduleRentalServiceOnChange(Item)
	
	CurrentData = Items.ServicePaymentSchedule.CurrentData;
	CurrentData.RentalServiceVAT = CalculateVATAmount(CurrentData.RentalService);
	
EndProcedure

&AtClient
Procedure ServicePaymentScheduleDateOnChange(Item)
	
	WhenScheduleDateChanges(Item.Parent.Name);
	
EndProcedure

&AtClient
Procedure ServicePaymentScheduleBeforeDeleteRow(Item, Cancel)
		
	ScheduleBeforeDeletion(Item, Cancel);
	
EndProcedure

&AtClient
Procedure ServicePaymentScheduleBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	ScheduleBeforeAdding(Item, Cancel, Copy);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServiceAccrualSchedule

&AtClient
Procedure ServiceAccrualScheduleOnChange(Item)
	UpdateTotals(ThisObject);
EndProcedure

&AtClient
Procedure ServiceAccrualScheduleRentalServiceOnChange(Item)
	
	CurrentData = Items.ServiceAccrualSchedule.CurrentData;
	CurrentData.RentalServiceVAT = CalculateVATAmount(CurrentData.RentalService);
	
EndProcedure

&AtClient
Procedure ServiceAccrualScheduleDateOnChange(Item)
	
	WhenScheduleDateChanges(Item.Parent.Name);
	
EndProcedure

&AtClient
Procedure ServiceAccrualScheduleBeforeDeleteRow(Item, Cancel)
		
	ScheduleBeforeDeletion(Item, Cancel);
	
EndProcedure

&AtClient
Procedure ServiceAccrualScheduleBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)

	ScheduleBeforeAdding(Item, Cancel, Copy);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInterestAccrualSchedule

&AtClient
Procedure InterestAccrualScheduleOnChange(Item)
	UpdateTotals(ThisObject);
EndProcedure

&AtClient
Procedure InterestAccrualScheduleDateOnChange(Item)
		
	WhenScheduleDateChanges(Item.Parent.Name);
	
EndProcedure

&AtClient
Procedure InterestAccrualScheduleBeforeDeleteRow(Item, Cancel)
	
	ScheduleBeforeDeletion(Item, Cancel);
	
EndProcedure

&AtClient
Procedure InterestAccrualScheduleBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	ScheduleBeforeAdding(Item, Cancel, Copy);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
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
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tiếp tục soạn';
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
Procedure FillInAmounts_PaymentSchedule(Command)
	
	FillInAmountsInChart("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure FillInAmounts_AccrualSchedule(Command)
	
	FillInAmountsInChart("ServiceAccrualSchedule");
	
EndProcedure

&AtClient
Procedure ImportSchedulePaymentSchedule(Command)
	
	ImportChart("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure ImportScheduleAccrualSchedule(Command)
	
	ImportChart("ServiceAccrualSchedule");
	
EndProcedure

&AtClient
Procedure DownloadAGraphAGraphOfPercentages(Command)
	
	ImportChart("InterestAccrualSchedule");
	
EndProcedure

&AtClient
Procedure Refill(Command)
	
	FillInSchedule();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillInAmountsInChart(TableName)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TableName", TableName);
	
	CallbackDescription = New CallbackDescription("FillInAmountsInChartCompletion", ThisObject, AdditionalParameters);
	
	CurrentData = Items[TableName].CurrentData;
	AmountOfFilling = ?(CurrentData = Undefined, 0, CurrentData.RentalService);

	ToolTipText = NStr("vi = 'Hãy nhập số tiền';
						|ru = 'Введите сумму';
						|en = 'Enter the amount'; fa = 'Enter the amount';
						|it = 'Введите сумму';
						|pl = 'Enter the amount';
						|tr = 'Tutarı girin'");
	TypeDescription = New TypeDescription("Number", New NumberQualifiers(31, 2, AllowedSign.Nonnegative));
	
	ShowInputValue(CallbackDescription, AmountOfFilling, ToolTipText, TypeDescription);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	#Region RentalService
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentForServicesRentalTotal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccrualRentalServiceTotal.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PaymentForServicesRentalTotal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("AccrualRentalServiceTotal");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Advances_Total");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
	#Region VAT
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Payment_NDS_Total.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Accrual_NDS_Total.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Payment_NDS_Total");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Accrual_NDS_Total");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Advances_Total");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
	#Region PaymentSchedule
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicePaymentSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicePaymentSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Date");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicePaymentSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region ScheduleOfAccruals
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServiceAccrualSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServiceAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Date");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServiceAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region InterestGraph
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.InterestAccrualSchedule.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use = True;
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InterestAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Date");
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InterestAccrualSchedule.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
EndProcedure

&AtServer
Function PutChartsInStorage() 
	
	UpdateGeneralCharts();
	
	GeneralServicePaymentSchedule.Sort("FixedAsset, Date");
	ScheduleOfAccrualOfServicesIsGeneral.Sort("FixedAsset, Date");
	InterestAccrualScheduleIsGeneral.Sort("FixedAsset, Date");
	
	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServicePaymentSchedule", GeneralServicePaymentSchedule.Unload());
	ContractSchedules.Insert("ServiceAccrualSchedule", ScheduleOfAccrualOfServicesIsGeneral.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", InterestAccrualScheduleIsGeneral.Unload());
	ContractSchedules.Insert("FATable", FATable.Unload());
	
	Return PutToTempStorage(ContractSchedules, UUID);
	
EndFunction

&AtServer
Procedure UpdateGeneralCharts()

	FoundLinesByFA = GeneralServicePaymentSchedule.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each FoundRow In FoundLinesByFA Do
		GeneralServicePaymentSchedule.Delete(FoundRow);
	EndDo;
	
	FoundLinesByFA = ScheduleOfAccrualOfServicesIsGeneral.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each FoundRow In FoundLinesByFA Do
		ScheduleOfAccrualOfServicesIsGeneral.Delete(FoundRow);
	EndDo;
	
	If TheInterestAccrualScheduleIsEnteredManually Then
		FoundLinesByFA = InterestAccrualScheduleIsGeneral.FindRows(New Structure("FixedAsset", FixedAsset));
		For Each FoundRow In FoundLinesByFA Do
			InterestAccrualScheduleIsGeneral.Delete(FoundRow);
		EndDo;
	EndIf;
	
	For Each CurrentLineOfGraph In ServicePaymentSchedule Do
		PaymentScheduleRow = GeneralServicePaymentSchedule.Add();
		FillPropertyValues(PaymentScheduleRow, CurrentLineOfGraph);
		PaymentScheduleRow.FixedAsset = FixedAsset;
	EndDo;
	
	For Each CurrentLineOfGraph In ServiceAccrualSchedule Do
		PaymentScheduleRow = ScheduleOfAccrualOfServicesIsGeneral.Add();
		FillPropertyValues(PaymentScheduleRow, CurrentLineOfGraph);
		PaymentScheduleRow.FixedAsset = FixedAsset;
	EndDo;
	
	If TheInterestAccrualScheduleIsEnteredManually Then
		For Each CurrentLineOfGraph In InterestAccrualSchedule Do
			PaymentScheduleRow = InterestAccrualScheduleIsGeneral.Add();
			FillPropertyValues(PaymentScheduleRow, CurrentLineOfGraph);
			PaymentScheduleRow.FixedAsset = FixedAsset;
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure CompleteEditingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	Modified = False;

	Close(PutChartsInStorage());
	
EndProcedure

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	CompleteEditing(Undefined);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotals(Form)
	
	PaymentForServicesRentalTotal = 0;
	Payment_NDS_Total = 0;
	AccrualRentalServiceTotal = 0;
	Accrual_NDS_Total = 0;
	Interest_Total = 0;
	Advances_Total = 0;
	
	Payment_RentalService_BeforeChange = 0;
	Payment_RentalService_VAT_BeforeChange = 0;
	AccrualOf_RentalService_BeforeChange = 0;
	Accrual_RentalService_VAT_BeforeChange = 0;
	
	For Each PlotLine In Form.ServicePaymentSchedule Do
		If PlotLine.Date < Form.Date Then
			Payment_RentalService_BeforeChange = Payment_RentalService_BeforeChange + PlotLine.RentalService;
			Payment_RentalService_VAT_BeforeChange = Payment_RentalService_VAT_BeforeChange + PlotLine.RentalServiceVAT;
			Continue;
		EndIf;
		PaymentForServicesRentalTotal = PaymentForServicesRentalTotal + PlotLine.RentalService;
		Payment_NDS_Total = Payment_NDS_Total + PlotLine.RentalServiceVAT;
	EndDo;
	
	For Each PlotLine In Form.ServiceAccrualSchedule Do
		If PlotLine.Date < Form.Date Then
			AccrualOf_RentalService_BeforeChange = AccrualOf_RentalService_BeforeChange + PlotLine.RentalService;
			Accrual_RentalService_VAT_BeforeChange = Accrual_RentalService_VAT_BeforeChange + PlotLine.RentalServiceVAT;
			Continue;
		EndIf;
		AccrualRentalServiceTotal = AccrualRentalServiceTotal + PlotLine.RentalService;
		Accrual_NDS_Total = Accrual_NDS_Total + PlotLine.RentalServiceVAT;
	EndDo;
	
	For Each PlotLine In Form.InterestAccrualSchedule Do
		If PlotLine.Date < Form.Date Then
			Continue;
		EndIf;
		Interest_Total = Interest_Total + PlotLine.Interests;
	EndDo;
	
	If Payment_RentalService_BeforeChange <> AccrualOf_RentalService_BeforeChange Then
		Balance = Payment_RentalService_BeforeChange - AccrualOf_RentalService_BeforeChange;
		AccrualRentalServiceTotal = AccrualRentalServiceTotal - Balance;
	EndIf;
	
	If Payment_RentalService_VAT_BeforeChange <> Accrual_RentalService_VAT_BeforeChange Then
		Balance = Payment_RentalService_VAT_BeforeChange - Accrual_RentalService_VAT_BeforeChange;
		Accrual_NDS_Total = Accrual_NDS_Total - Balance;
	EndIf;
	
	Form.PaymentForServicesRentalTotal = PaymentForServicesRentalTotal;
	Form.Payment_NDS_Total = Payment_NDS_Total;
	Form.AccrualRentalServiceTotal = AccrualRentalServiceTotal;
	Form.Accrual_NDS_Total = Accrual_NDS_Total;
	Form.Interest_Total = Interest_Total;
	Form.Advances_Total =
		AccrualRentalServiceTotal - Accrual_NDS_Total - PaymentForServicesRentalTotal + Payment_NDS_Total;
	
EndProcedure

&AtClient
Procedure FillInAmountsInChartCompletion(Value, AdditionalParameters) Export
	
	If Value <> Undefined Then
		
		TableName = AdditionalParameters.TableName;
		
		For Each HighlightedServicesLine In Items[TableName].SelectedRows Do
			
			ServiceLine_ = ThisObject[TableName].FindByID(HighlightedServicesLine);
			If ServiceLine_.Date < Date Then
				Continue;
			EndIf;
			ServiceLine_["RentalService"] = Value;
			ServiceLine_["RentalServiceVAT"] = VATAccountingERPClientServer.CalculateVATAmount(Value, VATRate, True);
			Modified = True;
			
		EndDo;
		
		If Modified Then 
			UpdateTotals(ThisObject);
		EndIf;

	EndIf;
	
EndProcedure

&AtClient
Function CalculateVATAmount(AmountIncludingVAT)
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
	Return VATAccountingERPClientServer.CalculateVATAmount(AmountIncludingVAT, CurPercentVAT, True);
	
EndFunction

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
			PropertyValue = Not (FormOwner.FormName = "CommonForm.FillIncomeRentalSchedules");
			Items.ReFill_PaymentSchedule.Enabled = PropertyValue;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSelectionsLabel()

	TemplateRow = NStr("vi = 'Hợp đồng: %1, Tài sản đang vận hành: %2';
						|ru = 'Договор: %1, Объект эксплуатации: %2';
						|en = 'Contract: %1, asset: %2'; fa = 'Contract: %1, asset: %2';
						|it = 'Договор: %1, Объект эксплуатации: %2';
						|pl = 'Contract: %1, asset: %2';
						|tr = 'Sözleşme: %1, Varlık: %2'");
	LabelFilters = StrTemplate(TemplateRow, String(Contract), String(FixedAsset));

EndProcedure

&AtClient
Procedure ImportChart(ChartName)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartName", ChartName);
	FormParameters.Insert("UniqueOwnerID", UUID);
	FormParameters.Insert("HasSecurityDeposit", False);
	FormParameters.Insert("ThereIsBuyoutOfLeasedAssets", False);
	
	OpenForm("Catalog.LeaseContract.Form.ImportingPaymentsAndAccrualsSchedule",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ImportChartCompletion", ThisObject, ChartName),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportChartCompletion(ClosingResult, ChartName) Export
	
	If TypeOf(ClosingResult) = Type("String") 
		And IsTempStorageURL(ClosingResult) Then
			
		UploadCompletionScheduleToServer(ClosingResult, ChartName);
	EndIf;

EndProcedure

&AtServer
Procedure UploadCompletionScheduleToServer(Val ResultAddress, Val ChartName)
	
	ChartTable = GetFromTempStorage(ResultAddress); // - ValueTable
	DestinationTable = ThisObject[ChartName];
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each PlotLine In DestinationTable Do
		If PlotLine.Date >= Date Then
			ArrayOfRowsToDelete_1.Add(PlotLine);
		EndIf;
	EndDo;
	For Each RowToDelete In ArrayOfRowsToDelete_1 Do
		DestinationTable.Delete(RowToDelete);
	EndDo;
	
	For Each PlotLine In ChartTable Do
		If PlotLine.Date > Date Then
			NewLineOfGraph = DestinationTable.Add();
			FillPropertyValues(NewLineOfGraph, PlotLine);
		EndIf;
	EndDo;
	DestinationTable.Sort("Date");
	
	LeasedAssetAccounting.FillInAmountsOfNDSInIncomeRentalCharts(ServicePaymentSchedule, ServiceAccrualSchedule, VATRate, Date);
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInSchedule()
	
	If Not ValueIsFilled(FixedAsset) Then
		Return;
	EndIf;
	
	LockFormDataForEdit();
	
	AddressOfGraphs = PlaceChartsInStorageToBeFilled();
	
	SelectedFA = New Array;
	SelectedFA.Add(FixedAsset);
	
	LeasedAssetAccountingClient.OpenFillingInRentalIncomeSchedules(
		ThisObject,
		ThisObject,
		SelectedFA,
		AddressOfGraphs,
		New CallbackDescription("FillInScheduleOfPaymentsAndAccrualsEnd", ThisObject));
		
EndProcedure
	
&AtServer
Function PlaceChartsInStorageToBeFilled()
	
	UpdateGeneralCharts();

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", ScheduleOfAccrualOfServicesIsGeneral.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", GeneralServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", InterestAccrualScheduleIsGeneral.Unload());
	ContractSchedules.Insert("FATable", FATable.Unload());

	Address = PutToTempStorage(ContractSchedules, UUID);
	
	Return Address;
	
EndFunction

&AtClient
Procedure FillInScheduleOfPaymentsAndAccrualsEnd(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	FillInScheduleOfPaymentsAndAccrualsEndOnServer(ClosingResult);

EndProcedure

&AtServer
Procedure FillInScheduleOfPaymentsAndAccrualsEndOnServer(Val ClosingResult)
	
	Modified = True;

	UploadCharts(ClosingResult);
	
EndProcedure

&AtServer
Procedure UploadCharts(AddressOfGraphs)
	
	ContractSchedules = GetFromTempStorage(AddressOfGraphs);
	
	GeneralServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	ScheduleOfAccrualOfServicesIsGeneral.Load(ContractSchedules.ServiceAccrualSchedule);
	InterestAccrualScheduleIsGeneral.Load(ContractSchedules.InterestAccrualSchedule);
	
	FATable.Load(ContractSchedules.FATable);
	
	ServicePaymentSchedule.Clear();
	ServiceAccrualSchedule.Clear();
	InterestAccrualSchedule.Clear();
	
	FoundLinesByFA = GeneralServicePaymentSchedule.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each FoundRow In FoundLinesByFA Do
		PaymentLine_ = ServicePaymentSchedule.Add();
		FillPropertyValues(PaymentLine_, FoundRow);
	EndDo;
	
	FoundLinesByFA = ScheduleOfAccrualOfServicesIsGeneral.FindRows(New Structure("FixedAsset", FixedAsset));
	For Each FoundRow In FoundLinesByFA Do
		AccrualLine = ServiceAccrualSchedule.Add();
		FillPropertyValues(AccrualLine, FoundRow);
	EndDo;
	
	ScheduleIsFilledFromRegister = False;
	If DisplayGraphOfPercentagesFromRegister And Not TheInterestAccrualScheduleIsEnteredManually Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	ScheduleOfInterestChargesOnIncomeRental.Date,
		|	ScheduleOfInterestChargesOnIncomeRental.Interests
		|FROM
		|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS ScheduleOfInterestChargesOnIncomeRental
		|WHERE
		|	ScheduleOfInterestChargesOnIncomeRental.Recorder = &Recorder
		|	AND ScheduleOfInterestChargesOnIncomeRental.FixedAsset = &FixedAsset";
		Query.SetParameter("Recorder", Ref);
		Query.SetParameter("FixedAsset", FixedAsset);
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			ScheduleIsFilledFromRegister = True;
			Selection = QueryResult.Select();
			While Selection.Next() Do
				InterestLine = InterestAccrualSchedule.Add();
				FillPropertyValues(InterestLine, Selection);
			EndDo;
		EndIf;
		
	EndIf;
	
	If Not ScheduleIsFilledFromRegister Then
		FoundLinesByFA = InterestAccrualScheduleIsGeneral.FindRows(New Structure("FixedAsset", FixedAsset));
		For Each FoundRow In FoundLinesByFA Do
			InterestLine = InterestAccrualSchedule.Add();
			FillPropertyValues(InterestLine, FoundRow);
		EndDo;
	EndIf;
	
	UpdateTotals(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Items = Form.Items;
	
	If UpdateAll Then
		
		ScheduleIsAlwaysEnteredManually = TypeOf(Form.Ref) = Type("DocumentRef.EnterRentalInvestmentBalance");
		Items.TheInterestAccrualScheduleIsEnteredManually.Enabled = Not ScheduleIsAlwaysEnteredManually;
		
	EndIf;
	
	If StructureOfChangedProps.Property("TheInterestAccrualScheduleIsEnteredManually")
		Or UpdateAll Then
			
		GraphEditingIsAvailable = 
			Form.TheInterestAccrualScheduleIsEnteredManually
			And Not Form.ReadOnly;
		
		Items.InterestAccrualSchedule.ReadOnly = Not GraphEditingIsAvailable;
		Items.InterestAccrualScheduleDownloadAGraphAGraphOfPercentages.Enabled = GraphEditingIsAvailable;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenScheduleDateChanges(ChartName)
	
	If Not ValueIsFilled(ChartName) Then
		Return;
	EndIf;

	CurrentData = Items[ChartName].CurrentData;
	
	ClearMessages();
	
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Date)
		And CurrentData.Date < Date Then
		WarningText = 
			StrTemplate(NStr("vi = 'Ngày lịch biểu ​​không được nhỏ hơn ngày chứng từ: %1.';
							|ru = 'Дата графика не должна быть меньше даты документа: %1.';
							|en = 'The schedule date cannot be earlier than the document date: %1.'; fa = 'The schedule date cannot be earlier than the document date: %1.';
							|it = 'Дата графика не должна быть меньше даты документа: %1.';
							|pl = 'The schedule date cannot be earlier than the document date: %1.';
							|tr = 'Program tarihi, belge tarihinden daha önce olmamalıdır: %1.'"), Format(Date, "DLF=D"));
		CommonClient.MessageToUser(WarningText,, ChartName);
		CurrentData.Date = '00010101';
	EndIf;

EndProcedure

&AtClient
Procedure ScheduleBeforeDeletion(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Date)
		And CurrentData.Date < Date Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduleBeforeAdding(Item, Cancel, Copy)
	
	If Copy And Item.CurrentData.Date < Date Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion