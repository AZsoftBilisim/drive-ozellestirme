
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ValueIsNotPopulated = NStr("vi = 'Không điền';
								|ru = 'Не заполняется';
								|en = 'Do not fill in'; fa = 'پر نشود';
								|it = 'Da non compilare';
								|pl = 'Nie jest wypełniane';
								|tr = 'Doldurulmadı'");
	SetConditionalAppearance();

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If TypeOf(Parameters.AdditionalParameters) = Type("Structure")
		And Parameters.AdditionalParameters.Property("PostingGenerationSetting") Then
		PostingGenerationSetting = Parameters.AdditionalParameters.PostingGenerationSetting;
	EndIf;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		CopyingValue = Parameters.CopyingValue;
	EndIf;
	
	AccountParties.Add("Dr");
	AccountParties.Add("Cr");
	
	UpdateBankingDetailsThatDependOnOperation();
	
	SetDefaultMeasurementSources();
	If Not ValueIsFilled(Parameters.Key) Then
		FillInDefaultMeasurementSources();
	EndIf;
	
	If Not ValueIsFilled(Parameters.Key) Or ValueIsFilled(Parameters.CopyingValue) Then
		Catalogs.PostingTemplatesForFinancialAccounting.InitializeComposer(ThisObject, Object.Operation);
	EndIf;
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		SavedSettings = Common.ObjectAttributeValue(Parameters.CopyingValue, "AdditionalSelection").Get();
		Catalogs.PostingTemplatesForFinancialAccounting.LoadSettings(ThisObject, SavedSettings);
		RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.PostingTemplate.Set(Parameters.CopyingValue);
		RecordSet.Read();
		If RecordSet.Count() = 1 Then
			PostingGenerationSetting = RecordSet[0].PostingGenerationSetting;
		EndIf;
	EndIf;
	
	ConfigureExtdimensionFilling(ThisForm, Object.PopulateExtraDimensionByCorrespondence);
	UpdateListOfExtdimensionInternationalAccounting();
	CompositionSetup = Undefined;
	InitializeComposerForExtdimensionFillSettings(CompositionSetup);
	
	CheckUsageInInternationalAccountingReflectionRules();
	
	SetHeadersForInvoiceRefinementCommands();
	
	SetFormItemEnabled();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTextAdditionalSelectionIsSet();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangedUseInRulesOfReflectionInInternationalAccounting" Then
		CheckUsageInInternationalAccountingReflectionRules();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If ValueIsFilled(PostingGenerationSetting) Then
		ReflectInAccountingPolicies(CurrentObject.Ref);
		CheckUsageInInternationalAccountingReflectionRules();
	EndIf;
	UpdateListOfExtdimensionInternationalAccounting();
	
	If CurrentObject.AdditionalProperties.Property("RecordingNew") 
			And CurrentObject.AdditionalProperties.RecordingNew And ValueIsFilled(CopyingValue) Then
		CopyInvoiceRefinementSettings();
	EndIf;
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("RecordedTransactionTemplate", Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If CurrentObject.PopulateExtraDimensionByCorrespondence Then
		GLAccounts = FillInExtraDimension.GetItems();
		CurrentObject.ExtraDimensionFillingSettings.Clear();
		For Each GLAccount In GLAccounts Do
			ComplianceWithExtdimension = GLAccount.GetItems();
			For Each Map In ComplianceWithExtdimension Do
				If Map.FillInFromSource And Not IsBlankString(Map.Expression) And Not IsBlankString(Map.RepresentationOfTheExpression)
					Or Not Map.FillInFromSource And ValueIsFilled(Map.SpecifiedValue) Then
					NewSetting = CurrentObject.ExtraDimensionFillingSettings.Add();
					FillPropertyValues(NewSetting, Map);
					NewSetting.ExtraDimensionPosition = GLAccount.ExtraDimensionPosition;
				EndIf;
			EndDo;// sub-konto accounts
		EndDo;// by accounts
	EndIf;// the filling of the subconto is set
	
	Catalogs.PostingTemplatesForFinancialAccounting.RecordAdditionalSelection(ThisObject, CurrentObject);
	
	CurrentObject.AdditionalProperties.Insert("RecordingNew", Not ValueIsFilled(CurrentObject.Ref));
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	Catalogs.PostingTemplatesForFinancialAccounting.InitializeComposer(ThisObject, CurrentObject.Operation);
	
	SavedSettings = CurrentObject.AdditionalSelection.Get();
	Catalogs.PostingTemplatesForFinancialAccounting.LoadSettings(ThisObject, SavedSettings);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationOnChange(Item)
	
	InitializeComposerForExtdimensionFillSettings();
	Object.AccountSpecificationSourceTypeDr = "";
	Object.AccountSpecificationSourceTypeCr = "";
	Object.SourceOfQuantityDr = "";
	Object.SourceOfQuantityCr = "";
	OperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DrAccountDefaultOnChange(Item)
	
	SetFormItemEnabled(Item.Name);
	UpdateDetailsThatDependOnDefaultAccount("Dr");
	
EndProcedure

&AtClient
Procedure CrAccountDefaultOnChange(Item)
	
	SetFormItemEnabled(Item.Name);
	UpdateDetailsThatDependOnDefaultAccount("Cr");
	
EndProcedure

&AtClient
Procedure AccountSpecificationSourceTypeDrOnChange(Item)
	
	SetFormItemEnabled(Item.Name);
	
EndProcedure

&AtClient
Procedure AccountSpecificationSourceTypeCrOnChange(Item)
	
	SetFormItemEnabled(Item.Name);
	
EndProcedure

&AtClient
Procedure UnitSourceDrOnChange(Item)
	
	UpdateDimensionGroupHeaders();
	
EndProcedure

&AtClient
Procedure UnitSourceCrOnChange(Item)
	
	UpdateDimensionGroupHeaders();
	
EndProcedure

&AtClient
Procedure SourceOfDirectionDrOnChange(Item)
	
	UpdateDimensionGroupHeaders();
	
EndProcedure

&AtClient
Procedure SourceOfDirectionCrOnChange(Item)
	
	UpdateDimensionGroupHeaders();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ComposerSettingsFilterOnChange(Item)
	
	Object.AdditionalFilterIsSet = Composer.Settings.Filter.Items.Count() > 0;
	UpdateTextAdditionalSelectionIsSet();
	
EndProcedure

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.FillInExtraDimension.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExtDimensionType", CurrentData.ExtDimensionType);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("CurrentExpression", CurrentData.Expression);
	
	OpenForm("CommonForm.SelectExtraDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FillInExtraDimensionRepresentationOfTheExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.FillInExtraDimension.CurrentData;
	CurrentData.Expression = ValueSelected;
	Modified = True;
	RowID = Items.FillInExtraDimension.CurrentRow;
	FillingExtdimensionPresentationOfExpressionProcessingOfSelectionOnServer(RowID);
	Items.FillInExtraDimension.EndEditRow(False);
	
EndProcedure

&AtServer
Procedure FillingExtdimensionPresentationOfExpressionProcessingOfSelectionOnServer(RowID)
	
	CurrentData = FillInExtraDimension.FindByID(RowID);
	CheckExpression(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ChangeTheModeOfExtraDimensionPopulationSetting(Command)
	
	Object.PopulateExtraDimensionByCorrespondence = Not Object.PopulateExtraDimensionByCorrespondence;
	Items.FillInSettingsGroup.Visible = Object.PopulateExtraDimensionByCorrespondence;
	Items.GroupSettingUpTheSubcontoFillingExplanation.Visible = Not Object.PopulateExtraDimensionByCorrespondence;
	ConfigureExtdimensionFilling(ThisForm, Object.PopulateExtraDimensionByCorrespondence);
	Modified = True;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateTextAdditionalSelectionIsSet()

	TextAdditionalFilterIsSet = ?(Object.AdditionalFilterIsSet, NStr("vi = 'Đã cài đặt';
																	|ru = 'Установлен';
																	|en = 'Set'; fa = 'مجموعه';
																	|it = 'Impostato';
																	|pl = 'Ustawiono';
																	|tr = 'Ayarlandı'"), "");

EndProcedure

&AtServer
Function CurrencyAccount_(Account)

	Return FinancialAccountingServerCached.AccountProperties(Account).Currency1;

EndFunction

&AtServer
Function QuantitativeAccount(Account)

	Return FinancialAccountingServerCached.AccountProperties(Account).Quantitative;

EndFunction

&AtServer
Procedure CheckUsageInInternationalAccountingReflectionRules()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(RulesOfPostingsInFinancialAccounting.PostingGenerationSetting) AS PostingGenerationSetting
	|FROM
	|	InformationRegister.RulesOfPostingsInFinancialAccounting AS RulesOfPostingsInFinancialAccounting
	|WHERE
	|	RulesOfPostingsInFinancialAccounting.PostingTemplate = &PostingTemplate
	|
	|HAVING
	|	COUNT(RulesOfPostingsInFinancialAccounting.PostingGenerationSetting) > 0";
	
	Query.SetParameter("PostingTemplate", Object.Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	If Selection.Next() Then
		UsageStatusInTheSetup = StrTemplate(" "+NStr("vi = 'Sử dụng';
													|ru = 'Используется';
													|en = 'Used'; fa = 'استفاده‌شده';
													|it = 'Si utilizza';
													|pl = 'W użyciu';
													|tr = 'Kullanılıyor'")+" (%1)", Selection.PostingGenerationSetting);
		If ChangingMFPSettingsIsAvailable Then
			Items.ConfigureUsage.Title = NStr("vi = 'Thay đổi';
												|ru = 'Изменить';
												|en = 'Change'; fa = 'تغییر';
												|it = 'Modificare';
												|pl = 'Change';
												|tr = 'Değiştir'");
		Else
			Items.ConfigureUsage.Title = NStr("vi = 'Xem';
												|ru = 'Посмотреть';
												|en = 'View'; fa = 'مشاهده';
												|it = 'Visualizzare';
												|pl = 'View';
												|tr = 'Görüntüle'");
		EndIf;
	Else
		UsageStatusInTheSetup = " "+ NStr("vi = 'Không sử dụng ';
											|ru = 'Не используется';
											|en = 'Not used'; fa = 'استفاده نمی‌شود';
											|it = 'Non viene utilizzato';
											|pl = 'Nie używane';
											|tr = 'Kullanılmaz'");
		Items.ConfigureUsage.Title = NStr("vi = 'Tùy chỉnh';
											|ru = 'Настроить';
											|en = 'Customize'; fa = 'سفارشی‌سازی';
											|it = 'Impostare';
											|pl = 'Customize';
											|tr = 'Ayarla'");
		Items.ConfigureUsage.Visible = ChangingMFPSettingsIsAvailable;
	EndIf;

EndProcedure

&AtServer
Procedure ReflectInAccountingPolicies(PostingTemplate)

	RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingGenerationSetting.Set(PostingGenerationSetting);
	RecordSet.Filter.PostingTemplate.Set(PostingTemplate);
	
	NewRecord = RecordSet.Add();
	NewRecord.PostingGenerationSetting = PostingGenerationSetting;
	NewRecord.PostingTemplate = PostingTemplate;
	
	RecordSet.Write();

EndProcedure

&AtServer
Procedure CopyInvoiceRefinementSettings()
	
	SourceRecordset = InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting.CreateRecordSet();
	SourceRecordset.Filter.PostingTemplate.Set(CopyingValue);
	SourceRecordset.Read();
	RecordsTable = SourceRecordset.Unload();
	
	RecordsTable.FillValues(Object.Ref, "PostingTemplate");
	
	RecordSet = InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.PostingTemplate.Set(Object.Ref);
	RecordSet.Load(RecordsTable);
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure SetHeadersForInvoiceRefinementCommands()

	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	If Not ChangingMFPSettingsIsAvailable Then
		For Each AccountSide In AccountParties Do
			DrCr = AccountSide.Value;
			Command = Items["ConfigureInvoiceRefinement"+DrCr]; // FormCommand - 
			Command.Title =  StrTemplate(NStr("vi = 'Xem sàng lọc hóa đơn%1';
												|ru = 'Посмотреть уточнение счета %1';
												|en = 'View account specification %1'; fa = 'View account specification %1';
												|it = 'Visualizzare indicazione di conto %1';
												|pl = 'Zobacz uściślenie rachunku %1';
												|tr = '%1 hesap iyileştirmesini görüntüle'"),DrCr);
		EndDo;
	EndIf;

EndProcedure

&AtServer
Function SourcesOfInvoiceRefinement()
	
	SourcesOfInvoiceRefinement = Undefined;
	
	If Object.Operation = Catalogs.BusinessTransactionsSettings.DepreciationOfNonCurrentAssets Then
		
		SourcesOfInvoiceRefinement = New Map;
		SourcesOfInvoiceRefinement.Insert(
			Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpenses,
			New Structure("FieldName", "HFCRevenueExpenditure"));
		
	Else
		
		DataSource = Common.ObjectAttributeValue(Object.Operation, "DataSource");
		SourcesOfInvoiceRefinement = FinancialAccountingServerCached.SourcesOfInvoiceRefinement(DataSource);
		
	EndIf;
	
	Return SourcesOfInvoiceRefinement;
	
EndFunction

&AtServer
Procedure FillInDefaultMeasurementSources()

	If Items.UnitSourceDr.ChoiceList.FindByValue(DefaultDepartmentSource) <> Undefined Then
		Object.UnitSourceDr = DefaultDepartmentSource;
		Object.UnitSourceCr = DefaultDepartmentSource;
	EndIf;
	
	For Each AccountSide In AccountParties Do
		
		DrCr = AccountSide.Value;
		
		If Not ValueIsFilled(Object["SourceOfDirection"+DrCr])Then
			Object["SourceOfDirection"+DrCr] = DefaultDrDirection;
		EndIf;
		
		If Not ValueIsFilled(Object["SourceOfQuantity"+DrCr]) Then
			Object["SourceOfQuantity"+DrCr] = DefaultDrQuantity;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetDefaultMeasurementSources()

	TypesOfRegisteredRecords = Common.ObjectAttributesValues(Object.Operation, "DataSource,Receipt,Expense");
	
	DataSource = TypesOfRegisteredRecords.DataSource;
	TypesOfRegisteredRecords.Delete("DataSource");
	
	If IsBlankString(DataSource) Then
		Return;
	EndIf;
	
	DefaultDepartmentSource = Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation;
	If StrFind("VATPurchaseBookEntries,VATSalesBookEntries",DataSource) > 0 Then
		DefaultDepartmentSource = Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.DocumentPayments;
	EndIf;
	
	// Direction of activity
	AccountingDataTypes = Enums.AccountingDataTypes;
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	EmptySource = SourcesOfDirections.EmptyRef();
	
	DirectionOfTravel = New Map;
	DirectionOfTravel.Insert(AccountingDataTypes.Products, SourcesOfDirections.ProductLineOfBusiness);
	DirectionOfTravel.Insert(AccountingDataTypes.Counterparties, SourcesOfDirections.CounterpartyLineOfBusiness);
	DirectionOfTravel.Insert(AccountingDataTypes.Cash, SourcesOfDirections.LineOfBusinessCash);
	DirectionOfTravel.Insert(AccountingDataTypes.IncomeExpenses, SourcesOfDirections.LineOfBusinessItems);
	DirectionOfTravel.Insert(AccountingDataTypes.OtherAssetsLiabilities, SourcesOfDirections.LineOfBusinessItems);
	DirectionOfTravel.Insert(AccountingDataTypes.EmptyRef(), EmptySource);
	
	SymmetricRegisters = New Structure;
	SymmetricRegisters.Insert("CashFlow");
	SymmetricRegisters.Insert("RecordsIncomeExpensesOtherAssetsLiabilities");
	SymmetricRegisters.Insert("RecordsCounterpartyCounterparty");
	SymmetricRegisters.Insert("RecordsProductsProducts");
	
	ResidualRegisters = New Structure;
	ResidualRegisters.Insert("FixedAssetsDepreciationCharge");
	ResidualRegisters.Insert("FACost");
	ResidualRegisters.Insert("IntangibleAssetsAmortizationCharge");
	ResidualRegisters.Insert("IACost");
	
	LineOfBusiness = SourcesOfDirections.LineOfBusiness;
	CorLineOfBusiness = SourcesOfDirections.CorLineOfBusiness;
	For Each RecordType In TypesOfRegisteredRecords Do
		DrCr = ?(RecordType.Key = "Receipt", "Dr", "Cr");
		SourceOfDirection = DirectionOfTravel[RecordType.Value];
		If SymmetricRegisters.Property(DataSource) Then
			SourceOfDirection = ?(RecordType.Key = "Receipt", CorLineOfBusiness, LineOfBusiness);
		EndIf;
		If ResidualRegisters.Property(DataSource) And ValueIsFilled(SourceOfDirection)
			Or StrFind("VATPurchaseBookEntries,VATSalesBookEntries",DataSource) > 0 Then
			SourceOfDirection = LineOfBusiness;
		EndIf;
		DefaultDirection = ?(DrCr = "Dr", "DefaultDrDirection", "DefaultCrDirection");
		ThisForm[DefaultDirection] = SourceOfDirection;
		DirectionSourceField = Items["SourceOfDirection"+DrCr]; // FormField -  
		DirectionSourceField.Enabled = SourceOfDirection <> EmptySource;
	EndDo;
	
	IndicatorQuantity = Enums.IndicatorsOfAnalyticalRegisters.Count;
	IndicatorCorQuantity = Enums.IndicatorsOfAnalyticalRegisters.CorQuantity;
	If Items.SourceOfQuantityDr.ChoiceList.FindByValue(IndicatorQuantity) <> Undefined Then
		DefaultDrQuantity = IndicatorQuantity;
	EndIf;
	If Items.SourceOfQuantityCr.ChoiceList.FindByValue(IndicatorCorQuantity) <> Undefined Then
		DefaultCrQuantity = IndicatorCorQuantity;
	ElsIf Items.SourceOfQuantityCr.ChoiceList.FindByValue(IndicatorQuantity) <> Undefined Then
		DefaultCrQuantity = IndicatorQuantity;
	EndIf;
	
EndProcedure

#Region ManagingAvailabilityOfFormElements

&AtServer
Procedure SetFormItemEnabled(FormItemName = Undefined)

	Items.ChangeTheModeOfExtraDimensionPopulationSetting.Enabled = AccessRight("Edit", Metadata.Catalogs.PostingTemplatesForFinancialAccounting);
	
	UpdateAll = FormItemName = Undefined;
	If UpdateAll Or FormItemName = "Operation" Then
		SetAvailabilityWhenOperationChanges();
	EndIf;
	
	For Each AccountSide In AccountParties Do
		
		DrCr = AccountSide.Value;
		
		If UpdateAll Or FormItemName = "AccountSpecificationSourceType"+DrCr Then
			SetAvailabilityWhenChangingTypeOfInvoiceRefinementSource(DrCr)
		EndIf;
		
		DefaultAccount = ?(DrCr = "Dr", "DrAccountDefault", "CrAccountDefault");
		If UpdateAll Or FormItemName = DefaultAccount Then
			SetAvailabilityOfAmountSourceInCurrency(DrCr);
			SetQuantitySourceAvailability(DrCr);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAvailabilityWhenOperationChanges()
	
	OperationCompleted_ = ValueIsFilled(Object.Operation);
	
	SetItemAvailability("BookAmountSource", OperationCompleted_);
	
	For Each AccountSide In AccountParties Do
		
		DrCr = AccountSide.Value;
		
		SetItemAvailability("AccountSpecificationSourceType"+DrCr, OperationCompleted_);
		
		SetItemAvailability("TheGroupOfDimensions"+DrCr, OperationCompleted_);
		
		SetItemAvailability("SourceOfAmountInCurrency"+DrCr, OperationCompleted_);
		
		SetAvailabilityOfInvoiceRefinementSource(DrCr);
		
		SetAccountRefinementSettingsToBeAvailable(DrCr);
		
		SetAvailabilityOfAmountSourceInCurrency(DrCr);
		
		SetQuantitySourceAvailability(DrCr);
		
	EndDo;
	
	DepreciationOperation = Object.Operation = Catalogs.BusinessTransactionsSettings.DepreciationOfNonCurrentAssets;
	
	Items.ManualSpecificationOfEntry.Visible = Not DepreciationOperation;
	
	Items.TheGroupOfDimensionsDr.Visible = Not DepreciationOperation;
	Items.TheGroupOfDimensionsCr.Visible = Not DepreciationOperation;
	Items.SourceOfAmountInCurrencyDr.Visible = Not DepreciationOperation;
	Items.DecorationExplanationOfTheResourceAmountsInTheDebitCurrency.Visible = Not DepreciationOperation;
	Items.ChangeTransactionSignWhileRecordingInAccounting.Visible = Not DepreciationOperation;
	
	Items.PageCreditGroup.CurrentPage = ?(
		DepreciationOperation,
		Items.LoanGroupDepreciationPage,
		Items.CreditGroupDefaultPage);
	
	Items.AdditionalSelectionGroup.Visible = ValueIsFilled(AddressOfDataCompositionSchema);
	
	UpdateDimensionGroupHeaders();
	
EndProcedure

&AtServer
Procedure SetAvailabilityWhenChangingTypeOfInvoiceRefinementSource(DrCr)

	SetAccountRefinementSettingsToBeAvailable(DrCr);

EndProcedure

&AtServer
Procedure SetAvailabilityOfInvoiceRefinementSource(DrCr)

	ElementAvailability = Items["AccountSpecificationSourceType"+DrCr].ChoiceList.Count() > 0;
	SetItemAvailability("AccountSpecificationSourceType"+DrCr, ElementAvailability);

EndProcedure

&AtServer
Procedure SetAccountRefinementSettingsToBeAvailable(DrCr)

	ElementAvailability = ValueIsFilled(Object.Operation) And ValueIsFilled(Object["AccountSpecificationSourceType"+DrCr]);
	SetItemAvailability("ConfigureInvoiceRefinement"+DrCr, ElementAvailability);

EndProcedure

&AtServer
Procedure SetAvailabilityOfAmountSourceInCurrency(DrCr)

	DefaultAccount = ?(DrCr = "Dr", "DrAccountDefault", "CrAccountDefault");
	ElementAvailability = Items["SourceOfAmountInCurrency"+DrCr].ChoiceList.Count() > 0 And CurrencyAccount_(Object[DefaultAccount]);
	SetItemAvailability("SourceOfAmountInCurrency"+DrCr, ElementAvailability);

EndProcedure

&AtServer
Procedure SetQuantitySourceAvailability(DrCr)

		DefaultAccount = ?(DrCr = "Dr", "DrAccountDefault", "CrAccountDefault");
	SourceOfQuantity = "SourceOfQuantity"+DrCr;
	ElementAvailability = Items[SourceOfQuantity].ChoiceList.Count() > 0 And QuantitativeAccount(Object[DefaultAccount]);
	SetItemAvailability(SourceOfQuantity, ElementAvailability);
	If Not ElementAvailability Then
		Object[SourceOfQuantity] = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure SetItemAvailability(TagName, ElementAvailability)

	FormItem = Items[TagName]; // FormField - 
	FormItem.Enabled = ElementAvailability;

EndProcedure

#EndRegion

#Region UpdatingDetailsAndFormElements

&AtServer
Procedure OperationWhenChangingOnServer()
	
	UpdateBankingDetailsThatDependOnOperation();
	SetDefaultMeasurementSources();
	FillInDefaultMeasurementSources();
	SetFormItemEnabled("Operation");
	
EndProcedure

&AtServer
Procedure UpdateBankingDetailsThatDependOnOperation()

	DataSource = Common.ObjectAttributeValue(Object.Operation, "DataSource");
	
	FillSelectionListsByDataSource(
		"AccountSpecificationSourceTypeDr", "AccountSpecificationSourceTypeCr", DataSource);
	FillSelectionListsByDataSource(
		"SourceOfAmountInCurrencyDr", "SourceOfAmountInCurrencyCr", DataSource);
	FillSelectionListsByDataSource(
		"UnitSourceDr", "UnitSourceCr", DataSource, "AddEmptyValue");
	FillSelectionListsByDataSource(
		"SourceOfDirectionDr", "SourceOfDirectionDr", DataSource, "AddEmptyValue");
	FillSelectionListsByDataSource(
		"SourceOfQuantityDr", "SourceOfQuantityCr", DataSource);
	FillInBalanceAmountSourceSelectionList();
	
	Catalogs.PostingTemplatesForFinancialAccounting.InitializeComposer(ThisObject, Object.Operation);

EndProcedure

&AtClient
Procedure UpdateDetailsThatDependOnDefaultAccount(DrCr)

	AmountSourceField = Items["SourceOfAmountInCurrency"+DrCr]; // TextBox - 
	If Not AmountSourceField.Enabled Then
		ClearAmountSourceInCurrency(DrCr);
	EndIf;
	
	QuantitySourceField = Items["SourceOfQuantity"+DrCr]; // TextBox -
	If Not QuantitySourceField.Enabled Then
		ClearQuantitySource(DrCr);
	Else
		Object["SourceOfQuantity"+DrCr] = ?(DrCr = "Dr", DefaultDrQuantity, DefaultCrQuantity);
	EndIf;

EndProcedure

&AtServer
Procedure FillInBalanceAmountSourceSelectionList()

	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegisterIndicators.Factor AS Factor
	|FROM
	|	Catalog.BusinessTransactionsSettings.RegisterIndicators AS RegisterIndicators
	|WHERE
	|	RegisterIndicators.Use
	|	AND RegisterIndicators.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.Operation);
	
	Items.BookAmountSource.ChoiceList.LoadValues(Common.UnloadColumn(Query.Execute().Unload(), "Factor"));

EndProcedure

&AtServer
Procedure FillSelectionListsByDataSource(TagNameDr, TagNameCr, DataSource, EmptyValue = Undefined)

	SelectionLists = New Structure;
	SelectionLists.Insert(TagNameDr, Items[TagNameDr].ChoiceList);
	SelectionLists[TagNameDr].Clear();
	SelectionLists.Insert(TagNameCr, Items[TagNameCr].ChoiceList);
	SelectionLists[TagNameCr].Clear();
	
	If TagNameDr = "AccountSpecificationSourceTypeDr" Then
		Sources = SourcesOfInvoiceRefinement();
	ElsIf TagNameDr = "SourceOfAmountInCurrencyDr" Then
		Sources = FinancialAccountingServerCached.IndicatorsInCurrency(DataSource);
	ElsIf TagNameDr = "UnitSourceDr" Then
		Sources = FinancialAccountingServerCached.SourcesOfDivisions(DataSource);
	ElsIf TagNameDr = "SourceOfDirectionDr" Then
		Sources = FinancialAccountingServerCached.SourcesOfDirections(DataSource);
	ElsIf TagNameDr = "SourceOfQuantityDr" Then
		Sources = FinancialAccountingServerCached.QuantityIndicators(DataSource);
	EndIf;

	If Sources = Undefined Then
		Return;
	EndIf;
	
	For Each Source In Sources Do
		For Each List In SelectionLists Do
			List.Value.Add(Source.Key);
		EndDo;
	EndDo;
	
	For Each List In SelectionLists Do
		List.Value.SortByPresentation();
	EndDo;
	
	If EmptyValue <> Undefined Then
		For Each List In SelectionLists Do
			List.Value.Add(Undefined, ValueIsNotPopulated);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function ClearAmountSourceInCurrency(DrCr)

	Object["SourceOfAmountInCurrency"+DrCr] = "";

EndFunction

&AtClient
Function ClearQuantitySource(DrCr)

	Object["SourceOfQuantity"+DrCr] = "";

EndFunction

#EndRegion

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	CreateDivisionSources(Items.UnitSourceDr.Name);
	CreateDivisionSources(Items.UnitSourceCr.Name);
	
	#Region DesignOfExtdimensionFillingTable
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionSpecifiedValue");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Visible");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionMissingInAvailableFields");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionRepresentationOfTheExpression");

	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Giá trị đã chỉ ra';
							|ru = 'Указанное значение';
							|en = 'Specified value'; fa = 'مقدار مشخص‌شده';
							|it = 'Valore indicato';
							|pl = 'Wskazana wartość';
							|tr = 'Belirtilen değer'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.FillInFromSource");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	Appearance.Use = True;
	Appearance.Value = NStr("vi = 'Từ kế toán giao dịch';
							|ru = 'Из оперативного учета';
							|en = 'From operational accounting'; fa = 'از حسابداری عملیاتی';
							|it = 'Dalla contabilità operativa';
							|pl = 'Z ewidencji operacyjnej';
							|tr = 'Operasyonel muhasebeden'");
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("FillInExtraDimension.ExtDimensionType");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("Show");
	Appearance.Use = True;
	Appearance.Value = False;
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("MarkIncomplete");
	Appearance.Use = True;
	Appearance.Value = False;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionFillInFromSource");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionRepresentationOfTheExpression");
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("FillInExtraDimensionSpecifiedValue");
	
	//
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure CreateDivisionSources(TagName)
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TagName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("Text", ValueIsNotPopulated);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureExtdimensionFilling(Form, Val PopulateByCorrespondence)
	
	Items = Form.Items;
	Items.FillInSettingsGroup.Visible = PopulateByCorrespondence;
	Items.GroupSettingUpTheSubcontoFillingExplanation.Visible = Not PopulateByCorrespondence;
	If PopulateByCorrespondence Then
		Items.ChangeTheModeOfExtraDimensionPopulationSetting.Title = NStr("vi = 'Vô hiệu hóa cài đặt điền khoản mục nâng cao';
																			|ru = 'Отключить расширенную настройку заполнения субконто';
																			|en = 'Disable advanced settings of extra dimension population'; fa = 'Disable advanced settings of extra dimension population';
																			|it = 'Disattivare le impostazioni avanzate di compilazione del subconto';
																			|pl = 'Wyłącz ustawienia rozszerzone wypełniania subkonto';
																			|tr = 'Ekstra boyut doldurma gelişmiş uzantıyı aç'");
		Items.GroupFillingInExtDimension.Title = NStr("vi = 'Điền khoản mục (Xác định người dùng)';
														|ru = 'Заполнение субконто (Задано пользователем)';
														|en = 'Populate extra dimension (Specified by the user)'; fa = 'Populate extra dimension (Specified by the user)';
														|it = 'Compilazione subconto (Impostato dall''utente)';
														|pl = 'Wypełnianie subkonto (Określone przez użytkownika)';
														|tr = 'Ekstra boyut doldurulması (kullanıcı tarafından tanımlı)'");
	Else
		Items.ChangeTheModeOfExtraDimensionPopulationSetting.Title = NStr("vi = 'Thay đổi chế độ cài đặt điền khoản mục';
																			|ru = 'Изменить режим настройки заполнения субконто';
																			|en = 'Change the mode of extra dimension population setting'; fa = 'تغییر حالت تنظیم پرکردن بُعد اضافی';
																			|it = 'Modificare la modalità di impostazione di compilazione del subconto';
																			|pl = 'Zmień tryb ustawienia wypełniania subkonto';
																			|tr = 'Ekstra boyut doldurma ayarları modunu değiştir'");
		Items.GroupFillingInExtDimension.Title = NStr("vi = 'Điền khoản mục (Tự động)';
														|ru = 'Заполнение субконто (Автоматически)';
														|en = 'Populate extra dimension (Automatically)'; fa = 'پرکردن بُعد اضافی (خودکار)';
														|it = 'Compilazione subconto (Automaticamente)';
														|pl = 'Wypełnienie subkonto (Automatyczne)';
														|tr = 'Ekstra boyut doldurma (Otomatik)'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDimensionGroupHeaders()
	
	SetDimensionGroupHeader(NStr("vi = 'Nguồn đo Nợ';
								|ru = 'Источники измерений Дт';
								|en = 'Dimension sources Dr'; fa = 'منابع بُعد بدهکار';
								|it = 'Fonte di misurazione debito';
								|pl = 'Źródła pomiaru Wn';
								|tr = 'Boyutların kaynakları Borç'"), "Dr");
	SetDimensionGroupHeader(NStr("vi = 'Nguồn đo Có';
								|ru = 'Источники измерений Кт';
								|en = 'Dimension sources Cr'; fa = 'منابع بُعد بستانکار';
								|it = 'Fonti di musirazione del credito';
								|pl = 'Źródła pomiaru Ma';
								|tr = 'Boyutların kaynakları Alacak'"), "Cr");
	
EndProcedure

&AtServer
Procedure SetDimensionGroupHeader(Var_Title, DrCr)
	
	DefaultDirection = ?(DrCr = "Dr", "DefaultDrDirection", "DefaultCrDirection");
	If Object["UnitSource"+DrCr] <> DefaultDepartmentSource
		Or Object["SourceOfDirection"+DrCr] <> ThisForm[DefaultDirection] Then
		Var_Title = Var_Title + " (" + NStr("vi = 'Thay đổi';
											|ru = 'Изменены';
											|en = 'Changed'; fa = 'تغییریافته';
											|it = 'Conti modificati';
											|pl = 'Zmieniono';
											|tr = 'Değiştirildi'") + ")";
	EndIf;
	FormGroup = Items["TheGroupOfDimensions"+DrCr]; // FormGroup - 
	FormGroup.Title = Var_Title;
	FormGroup.CollapsedRepresentationTitle = Var_Title;
	
EndProcedure

&AtServer
Procedure InitializeComposerForExtdimensionFillSettings(CompositionSetup = Undefined)
	
	DataCompositionSchema = DataSourcesCached.DataAcquisitionScheme(Object.Operation);
	If DataCompositionSchema = Undefined Then
		Items.GroupFillingInExtDimension.Visible = False;
		Return;
	Else
		Items.GroupFillingInExtDimension.Visible = True;
	EndIf;
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	ExtraDimensionPopulationComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	If CompositionSetup <> Undefined Then
		ExtraDimensionPopulationComposer.LoadSettings(CompositionSetup);
	EndIf;
	ExtraDimensionPopulationComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServer
Procedure CheckExpression(SetupStrings)
	
	FinancialAccountingOfGeneralPurpose.CheckExtdimensionFillingExpression(SetupStrings, ExtraDimensionPopulationComposer);
	
EndProcedure

&AtServer
Procedure UpdateListOfExtdimensionInternationalAccounting(ExtraDimensionPosition = Undefined)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	PopulationSettings.ExtraDimensionPosition AS ExtraDimensionPosition,
	|	PopulationSettings.ExtDimensionType AS ExtDimensionType,
	|	PopulationSettings.FillInFromSource AS FillInFromSource,
	|	PopulationSettings.SpecifiedValue AS SpecifiedValue,
	|	PopulationSettings.Expression AS Expression,
	|	PopulationSettings.RepresentationOfTheExpression AS RepresentationOfTheExpression
	|INTO TTExtdimensionFilling
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting.ExtraDimensionFillingSettings AS PopulationSettings
	|WHERE
	|	PopulationSettings.Ref = &PostingTemplate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&DrInternationalAccountingAccount AS Account,
	|	MIN(ExtDimensionTypes.ExtDimensionNumber) AS ExtDimensionNumber,
	|	ExtDimensionTypes.ExtDimensionType
	|INTO TTExtdimensionDebit
	|FROM
	|	(SELECT
	|		ExtDimensionTypes.LineNumber AS ExtDimensionNumber,
	|		ExtDimensionTypes.ExtDimensionType AS ExtDimensionType
	|	FROM
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|	WHERE
	|		ExtDimensionTypes.Ref = &DrInternationalAccountingAccount
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ExtDimensionTypes.LineNumber+10 AS ExtDimensionNumber,
	|		ExtDimensionTypes.ExtDimensionType AS ExtDimensionType
	|	FROM
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|		INNER JOIN InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RefinementRules
	|		ON ExtDimensionTypes.Ref = RefinementRules.GLAccount
	|	WHERE
	|		RefinementRules.RecordType = VALUE(Enum.AccountingMovementKinds.Debit)
	|		AND RefinementRules.PostingTemplate = &PostingTemplate
	|		AND RefinementRules.GLAccount <> &DrInternationalAccountingAccount
	|		AND &SearchForExtdimensionDrRefinements
	|	)AS ExtDimensionTypes
	|GROUP BY
	|	ExtDimensionTypes.ExtDimensionType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&CrInternationalAccountingAccount AS Account,
	|	MIN(ExtDimensionTypes.ExtDimensionNumber) AS ExtDimensionNumber,
	|	ExtDimensionTypes.ExtDimensionType
	|INTO TTExtdimensionLoan
	|FROM
	|	(SELECT
	|		ExtDimensionTypes.LineNumber AS ExtDimensionNumber,
	|		ExtDimensionTypes.ExtDimensionType AS ExtDimensionType
	|	FROM
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|	WHERE
	|		ExtDimensionTypes.Ref = &CrInternationalAccountingAccount
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ExtDimensionTypes.LineNumber+10 AS ExtDimensionNumber,
	|		ExtDimensionTypes.ExtDimensionType AS ExtDimensionType
	|	FROM
	|		ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|		INNER JOIN InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RefinementRules
	|		ON ExtDimensionTypes.Ref = RefinementRules.GLAccount
	|	WHERE
	|		RefinementRules.RecordType = VALUE(Enum.AccountingMovementKinds.Credit)
	|		AND RefinementRules.PostingTemplate = &PostingTemplate
	|		AND RefinementRules.GLAccount <> &CrInternationalAccountingAccount
	|		AND &SearchForClarifyingExtdimensionCr
	|	)AS ExtDimensionTypes
	|GROUP BY
	|	ExtDimensionTypes.ExtDimensionType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""Dr"" AS ExtraDimensionPosition,
	|	PRESENTATION(DebitExtdimension.Account) AS Account,
	|	DebitExtdimension.ExtDimensionNumber AS ExtDimensionNumber,
	|	DebitExtdimension.ExtDimensionType AS ExtDimensionType,
	|	DebitExtdimension.ExtDimensionType.ValueType AS TypeDescription,
	|	ISNULL(FillInExtraDimension.FillInFromSource, TRUE) AS FillInFromSource,
	|	FillInExtraDimension.SpecifiedValue AS SpecifiedValue,
	|	FillInExtraDimension.Expression AS Expression,
	|	FillInExtraDimension.RepresentationOfTheExpression AS RepresentationOfTheExpression
	|FROM
	|	TTExtdimensionDebit AS DebitExtdimension
	|	LEFT JOIN TTExtdimensionFilling AS FillInExtraDimension
	|	ON DebitExtdimension.ExtDimensionType = FillInExtraDimension.ExtDimensionType
	|		AND FillInExtraDimension.ExtraDimensionPosition = ""Dr""
	|WHERE
	|	(&ExtraDimensionPosition = ""Dr"" OR &ExtraDimensionPosition = UNDEFINED)
	|ORDER BY
	|	DebitExtdimension.ExtDimensionNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""Cr"" AS ExtraDimensionPosition,
	|	PRESENTATION(ExtdimensionOfCredit.Account) AS Account,
	|	ExtdimensionOfCredit.ExtDimensionNumber AS ExtDimensionNumber,
	|	ExtdimensionOfCredit.ExtDimensionType AS ExtDimensionType,
	|	ExtdimensionOfCredit.ExtDimensionType.ValueType AS TypeDescription,
	|	ISNULL(FillInExtraDimension.FillInFromSource, TRUE) AS FillInFromSource,
	|	FillInExtraDimension.SpecifiedValue AS SpecifiedValue,
	|	FillInExtraDimension.Expression AS Expression,
	|	FillInExtraDimension.RepresentationOfTheExpression AS RepresentationOfTheExpression
	|FROM
	|	TTExtdimensionLoan AS ExtdimensionOfCredit
	|	LEFT JOIN TTExtdimensionFilling AS FillInExtraDimension
	|	ON ExtdimensionOfCredit.ExtDimensionType = FillInExtraDimension.ExtDimensionType
	|		AND FillInExtraDimension.ExtraDimensionPosition = ""Cr""
	|WHERE
	|	(&ExtraDimensionPosition = ""Cr"" OR &ExtraDimensionPosition = UNDEFINED)
	|ORDER BY
	|	ExtdimensionOfCredit.ExtDimensionNumber
	|;";
	
	Query.SetParameter("PostingTemplate", Object.Ref);
	Query.SetParameter("DrInternationalAccountingAccount", Object.DrAccountDefault);
	Query.SetParameter("CrInternationalAccountingAccount", Object.CrAccountDefault);
	Query.SetParameter("ExtraDimensionPosition",         ExtraDimensionPosition);
	Query.SetParameter("SearchForExtdimensionDrRefinements", ValueIsFilled(Object.AccountSpecificationSourceTypeDr));
	Query.SetParameter("SearchForClarifyingExtdimensionCr", ValueIsFilled(Object.AccountSpecificationSourceTypeCr));
	
	QueryResults = Query.ExecuteBatch();
	ExtDimensionSelectionDr = QueryResults[3].Select();
	ExtDimensionSelectionCr = QueryResults[4].Select();
	
	LinesToDelete = New Array; 
	For Each String In FillInExtraDimension.GetItems() Do
		If ExtraDimensionPosition = Undefined Or ExtraDimensionPosition = String.ExtraDimensionPosition Then
			LinesToDelete.Add(String);
		EndIf;
	EndDo;
	
	For Each String In LinesToDelete Do
		FillInExtraDimension.GetItems().Delete(String);
	EndDo;
	
	Template = "%1 %2 " + NStr("vi = 'và sửa đổi tài khoản';
								|ru = 'и уточненные счета';
								|en = 'and specified accounts'; fa = 'and specified accounts';
								|it = 'e indicati';
								|pl = 'i uściślenie rachunku';
								|tr = 've iyileştirilmiş hesaplar'");
	FillOutExtdimensionAccounts(ExtDimensionSelectionDr, NStr("vi = 'Nợ';
																|ru = 'Дт';
																|en = 'Dr'; fa = 'بد';
																|it = 'Debito';
																|pl = 'Wn';
																|tr = 'Borç'"), Template);
	FillOutExtdimensionAccounts(ExtDimensionSelectionCr, NStr("vi = 'Có';
																|ru = 'Кт';
																|en = 'Cr'; fa = 'بس';
																|it = 'Credito';
																|pl = 'Ma';
																|tr = 'Alacak'"), Template);
	
EndProcedure

&AtServer
Procedure FillOutExtdimensionAccounts(ExtDimensionSelection, AccountSide, Template)
	
	If ExtDimensionSelection.Count() Then
		InvoiceLine_ = FillInExtraDimension.GetItems().Add();
		InvoiceLine_.ExtraDimensionPosition = AccountSide;
		Account = ?(AccountSide = NStr("vi = 'Nợ';
										|ru = 'Дт';
										|en = 'Dr'; fa = 'بد';
										|it = 'Debito';
										|pl = 'Wn';
										|tr = 'Borç'"), Object.DrAccountDefault, Object.CrAccountDefault);
		InvoiceLine_.ExtraDimensionPositionPresentation = StrTemplate(Template, AccountSide, Account);
		InvoiceLine_.GetItems().Clear();
		While ExtDimensionSelection.Next() Do
			StringExtdimension = InvoiceLine_.GetItems().Add();
			FillPropertyValues(StringExtdimension, ExtDimensionSelection, , "ExtraDimensionPosition");
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion
