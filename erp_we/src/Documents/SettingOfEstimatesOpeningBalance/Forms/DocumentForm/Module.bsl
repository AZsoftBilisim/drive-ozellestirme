
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.DateOfRemainingGoods = BegOfMonth(Common.CurrentUserDate());
		OnReadCreateAtServer();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PresentationOfBalanceDate = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.DateOfRemainingGoods);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ByScenario And Not ValueIsFilled(Object.Scenario) Then
		Common.MessageToUser(CommonClientServer.FillingErrorText(, , "Scenario"), ,
			"Scenario", "Object", Cancel);
	EndIf;
	TabularSectionPresentation = Object.Ref.Metadata().TabularSections.BalanceOfEstimate.Synonym;
	If ByCompanies Then
		LinesToVerify = Object.BalanceOfEstimate.FindRows(New Structure("Organization",
			Catalogs.Companies.EmptyRef()));
		For Each RowToValidate In LinesToVerify Do
			Common.MessageToUser(CommonClientServer.FillingErrorText("Column", , "Organization",
				RowToValidate.LineNumber, TabularSectionPresentation), ,
				CommonClientServer.PathToTabularSection("BalanceOfEstimate",
				RowToValidate.LineNumber, "Organization"), "Object", Cancel);
		EndDo;
	EndIf;
	If ByBusinessUnits Then
		LinesToVerify = Object.BalanceOfEstimate.FindRows(New Structure("Department",
			Catalogs.BusinessStructure.EmptyRef()));
		For Each RowToValidate In LinesToVerify Do
			Common.MessageToUser(CommonClientServer.FillingErrorText("Column", , "Department",
				RowToValidate.LineNumber, TabularSectionPresentation), ,
				CommonClientServer.PathToTabularSection("BalanceOfEstimate",
				RowToValidate.LineNumber, "Department"), "Object", Cancel);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOfRemainingGoodsOnChange(Item)
	
	If ValueIsFilled(Object.Scenario) Then
		PlaceScriptCourseTableInTemporaryStorage();
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfRemainingGoodsClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure DateOfRemainingGoodsTuning(Item, Direction, StandardProcessing)
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing,
		Object.DateOfRemainingGoods, PresentationOfBalanceDate);
	Object.DateOfRemainingGoods = BegOfMonth(Object.DateOfRemainingGoods);
EndProcedure

&AtClient
Procedure DateOfRemainingGoodsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("DateOfRemainingGoodsStartChoiceCompletion", ThisObject);
	FormParameters = New Structure("Value, PeriodSelectionMode", Object.DateOfRemainingGoods, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection", FormParameters, ThisObject, UUID, , ,
		CloseHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DateOfRemainingGoodsStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	Object.DateOfRemainingGoods = BegOfMonth(SelectedPeriod);
	PresentationOfBalanceDate = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(
		Object.DateOfRemainingGoods);
	
EndProcedure

&AtClient
Procedure BudgetBalanceItemOnChange(Item)
	OnChangesInBudgetIndicator();
EndProcedure

&AtClient
Procedure ByScenarioOnChange(Item)
	
	If Not ByScenario Then
		Object.Scenario = Undefined;
		AddressOfScriptCourseTable = Undefined;
	EndIf;
	
	SetVisibility1(ThisObject);
	
EndProcedure

&AtClient
Procedure ByCompaniesOnChange(Item)
	
	If Not ByCompanies Then
		For Each TSRow In Object.BalanceOfEstimate Do
			TSRow.Organization = Undefined;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Object.BudgetBalanceItem) Then
		SetColumnPropertiesByCalculatedIndicator();
	EndIf;
	
EndProcedure

&AtClient
Procedure ByBusinessUnitsOnChange(Item)
	
	If Not ByBusinessUnits Then
		For Each TSRow In Object.BalanceOfEstimate Do
			TSRow.Department = Undefined;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScenarioOnChange(Item)
	
	If ValueIsFilled(Object.Scenario) Then
		PlaceScriptCourseTableInTemporaryStorage();
	Else
		AddressOfScriptCourseTable = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBalanceOfEstimate

&AtClient
Procedure BalanceOfEstimateBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	DoubleLineNumber = Undefined;
	If Not CancelEdit Then
		If LineDuplicatesExistingOne(Item.CurrentRow, DoubleLineNumber) Then
			MessageText = NStr("ru = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1';
										|vi = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1';
										|en = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1'; fa = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1';
										|it = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1';
										|pl = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1';
										|tr = 'Нельзя вводить строки с одинаковыми значениями.
										|Указанные значения уже встречаются в строке №%1'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, DoubleLineNumber);
			ShowMessageBox(, MessageText);
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BalanceOfCalculatedAnalyticsIndicatorONChange(Item)
	
	If ValueIsFilled(IndicatorParameters.DimensionCurrencies)
		And Item.Name = StringFunctionsClientServer.SubstituteParametersToString("BalanceOfCalculatedAnalyticsIndicator%1",
		IndicatorParameters.DimensionAddressCurrency) Then
		CurrentRow = Items.BalanceOfEstimate.CurrentData;
		DimensionValue = CurrentRow[StringFunctionsClientServer.SubstituteParametersToString("Dimension%1",
			IndicatorParameters.DimensionAddressCurrency)];
		If ValueIsFilled(DimensionValue) Then
			Currency = GetCurrencyFromAnalyticsValue(DimensionValue);
		Else
			Currency = Undefined;
		EndIf;
		If CurrentRow.Currency <> Currency Then
			CurrentRow.Currency = Currency;
			CurrentRow.AmountInCurrency = 0;
			CurrentRow.SumMan = 0;
			CurrentRow.SumCompl = 0;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BalanceOfEstimateCurrencyOnChange(Item)
	
	CurrentRow = Items.BalanceOfEstimate.CurrentData;
	CurrentRow.AmountInCurrency = 0;
	CurrentRow.SumMan = 0;
	CurrentRow.SumCompl = 0;
	
EndProcedure

&AtClient
Procedure BalanceOfEstimateAmountInCurrencyOnChange(Item)
	
	CurrentRow = Items.BalanceOfEstimate.CurrentData;
	If Not ValueIsFilled(CurrentRow.Currency) Then
		CommonClient.MessageToUser(CommonClientServer.FillingErrorText("Column", , "Currency",
			CurrentRow.LineNumber), ,
			CommonClientServer.PathToTabularSection("BalanceOfEstimate",
			CurrentRow.LineNumber, "Currency"), "Object");
		CurrentRow.AmountInCurrency = 0;
	Else
		RecalculateAmountMAN = False;
		RecalculateLocalAmount = False;
		If CurrentRow.Currency <> CurrencyOfManAccounting Then
			RecalculateAmountMAN = True;
		Else
			CurrentRow.SumMan = CurrentRow.AmountInCurrency;
		EndIf;
		If CurrentRow.Currency <> ?(ValueIsFilled(CurrentRow.Organization),
			SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(CurrentRow.Organization),
			CurrencyOfComplianceAccounting) Then
			RecalculateLocalAmount = True;
		Else
			CurrentRow.SumCompl = CurrentRow.AmountInCurrency;
		EndIf;
		If RecalculateAmountMAN Or RecalculateLocalAmount Then
			If ValueIsFilled(Object.Scenario) Then
				RecalculateAmountsOfMenSAndLocalSByForecastRatesInRowOfTablePart(CurrentRow.GetID(),
					RecalculateAmountMAN, RecalculateLocalAmount);
			Else
				RecalculateManAndLocalAmountsInRowOfTablePart(CurrentRow.GetID(), RecalculateAmountMAN,
					RecalculateLocalAmount);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BalanceOfEstimateSumManOnChange(Item)
	
	CurrentRow = Items.BalanceOfEstimate.CurrentData;
	If Not ValueIsFilled(CurrentRow.Currency) Then
		If CurrencyOfManAccounting <> ?(ValueIsFilled(CurrentRow.Organization),
			SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(CurrentRow.Organization),
			CurrencyOfComplianceAccounting) Then
			RecalculateLocalAmount = True;
		Else
			CurrentRow.SumCompl = CurrentRow.SumMan;
			RecalculateLocalAmount = False;
		EndIf;
		If RecalculateLocalAmount Then
			If ValueIsFilled(Object.Scenario) Then
				RecalculateAmountsOfMenSAndLocalSByForecastRatesInRowOfTablePart(CurrentRow.GetID(), False,
					RecalculateLocalAmount);
			Else
				RecalculateManAndLocalAmountsInRowOfTablePart(CurrentRow.GetID(), False, RecalculateLocalAmount);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
 
// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInActualInitialBalances(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("ActualDataLimit", BegOfDay(Object.DateOfRemainingGoods - 1));
	If Object.BalanceOfEstimate.Count() > 0 Then
		Notification = New CallbackDescription("FillBalanceCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Tiếp tục?';
										|ru = 'Перед заполнением табличная часть будет очищена. Продолжить?';
										|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
										|it = 'Prima della compilazione, la parte tabulare sarà cancellata. Continuare?';
										|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Kontynuować?';
										|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillBalanceServer(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInBorderOfActualData(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	If Not ByScenario Then
		CommonClient.MessageToUser(NStr("vi = 'Việc điền là có thể chỉ theo kịch bản cụ thể.';
										|ru = 'Заполнение возможно только по конкретному сценарию.';
										|en = 'You can fill in only by a specific scenario.'; fa = 'You can fill in only by a specific scenario.';
										|it = 'You can fill in only by a specific scenario.';
										|pl = 'You can fill in only by a specific scenario.';
										|tr = 'Doldurma işlemi sadece belirli bir senaryoya göre mümkündür.'"), , "ByScenario");
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	If Object.BalanceOfEstimate.Count() > 0 Then
		CallbackDescription = New CallbackDescription("FillBalanceCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Tiếp tục?';
												|ru = 'Перед заполнением табличная часть будет очищена. Продолжить?';
												|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
												|it = 'Prima della compilazione, la parte tabulare sarà cancellata. Continuare?';
												|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Kontynuować?';
												|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		EnterActualDataBoundaryToFillInBalances(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPlannedFinalBalances(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	If Not ByScenario Then
		CommonClient.MessageToUser(NStr("vi = 'Việc điền là có thể chỉ theo kịch bản cụ thể.';
										|ru = 'Заполнение возможно только по конкретному сценарию.';
										|en = 'You can fill in only by a specific scenario.'; fa = 'You can fill in only by a specific scenario.';
										|it = 'You can fill in only by a specific scenario.';
										|pl = 'You can fill in only by a specific scenario.';
										|tr = 'Doldurma işlemi sadece belirli bir senaryoya göre mümkündür.'"), , "ByScenario");
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("ActualDataLimit", Undefined);
	If Object.BalanceOfEstimate.Count() > 0 Then
		Notification = New CallbackDescription("FillBalanceCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Tiếp tục?';
										|ru = 'Перед заполнением табличная часть будет очищена. Продолжить?';
										|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
										|it = 'Prima della compilazione, la parte tabulare sarà cancellata. Continuare?';
										|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Kontynuować?';
										|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillBalanceServer(AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInPropertiesOfBudgetIndicator();
	
	ByScenario = ValueIsFilled(Object.Scenario);
	If ByScenario Then
		PlaceScriptCourseTableInTemporaryStorage();
	EndIf;
	CurrencyOfManAccounting = SettingsValueCached.ManagementAccountingCurrency();
	CurrencyOfComplianceAccounting = SettingsValueCached.DefaultBaseCurrency();
	AddressOfCurrencyExchangeRateCache = PutToTempStorage(ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache(),
		UUID);
	AddressOfAnalyticsValueCache = PutToTempStorage(New Map, UUID);
	
	NumberOfRowsOfTablePart = Object.BalanceOfEstimate.Count();
	If NumberOfRowsOfTablePart > 0 Then
		TheStructureOfTheSearch = New Structure("Organization", Catalogs.Companies.EmptyRef());
		NumberOfRowsFound = Object.BalanceOfEstimate.FindRows(TheStructureOfTheSearch).Count();
		ByCompanies = (NumberOfRowsOfTablePart > NumberOfRowsFound);
		TheStructureOfTheSearch = New Structure("Department", Catalogs.BusinessStructure.EmptyRef());
		NumberOfRowsFound = Object.BalanceOfEstimate.FindRows(TheStructureOfTheSearch).Count();
		ByBusinessUnits = (NumberOfRowsOfTablePart > NumberOfRowsFound);
	Else
		ByCompanies = False;
		ByBusinessUnits = False;
	EndIf;
	
	SetVisibility1(ThisObject);
	SetColumnPropertiesByCalculatedIndicator();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	Form.Items.Scenario.Visible = Form.ByScenario;
	
EndProcedure

&AtServer
Procedure SetColumnPropertiesByCalculatedIndicator()

	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	If TypesOfIndicatorAnalytics = Undefined Then
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ColumnName = StringFunctionsClientServer.SubstituteParametersToString("BalanceOfCalculatedAnalyticsIndicator%1",
				DimensionNumber);
			Items[ColumnName].Visible = False;
			Items[ColumnName].TypeRestriction = New TypeDescription;
		EndDo;
	Else
		OwnersCompliance = FinancialReportingCached.MatchingSelectionsByOwner();
		ComplianceByOrganization = BudgetingCached.TypesOfAnalyticsRelatedToOrganization();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ColumnName = StringFunctionsClientServer.SubstituteParametersToString("BalanceOfCalculatedAnalyticsIndicator%1",
				DimensionNumber);
			RowColumnName = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1Description",
				DimensionNumber);
			If ValueIsFilled(TypesOfIndicatorAnalytics[RowColumnName]) Then
				Items[ColumnName].Title = TypesOfIndicatorAnalytics[RowColumnName];
				StringColumnValueType = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1ValueType",
					DimensionNumber);
				Items[ColumnName].Visible = True;
				Items[ColumnName].TypeRestriction = TypesOfIndicatorAnalytics[StringColumnValueType];
				StringAdditionalProperty = StringFunctionsClientServer.SubstituteParametersToString(
					"DimensionKind%1AdditionalProperty", DimensionNumber);
				If ValueIsFilled(TypesOfIndicatorAnalytics[StringAdditionalProperty]) Then
					FormSelectionParameters = CommonClientServer.ValueInArray(New ChoiceParameter("Filter.Owner",
						TypesOfIndicatorAnalytics[StringAdditionalProperty]));
					Items[ColumnName].ChoiceParameters = New FixedArray(FormSelectionParameters);
				Else
					AddedCommunicationParametersByOwner = False;
					For Each Type In Items[ColumnName].TypeRestriction.Types() Do
						If AddedCommunicationParametersByOwner Then
							Break;
						EndIf;
						OwnerTypes = OwnersCompliance[Type];
						If OwnerTypes <> Undefined Then
							For OwnerSAnalyticsNumber = 1 To DimensionNumber - 1 Do
								If AddedCommunicationParametersByOwner Then
									Break;
								EndIf;
								NumberOfAnalyticsBeingChecked = DimensionNumber - OwnerSAnalyticsNumber;
								DescriptionOfTypesOfAnalyticsToBeChecked = TypesOfIndicatorAnalytics[StringFunctionsClientServer.SubstituteParametersToString(
									"DimensionKind%1ValueType", OwnerSAnalyticsNumber)];
								For Each TypeRow In OwnerTypes Do
									If DescriptionOfTypesOfAnalyticsToBeChecked.ContainsType(TypeRow.Type) Then
										PathToDataOfAnalyticsBeingChecked = StringFunctionsClientServer.SubstituteParametersToString(
											"Items.BalanceOfEstimate.CurrentData.Dimension%1", NumberOfAnalyticsBeingChecked);
										ChoiceParameterLinks = CommonClientServer.ValueInArray(New ChoiceParameterLink(
											"Filter." + TypeRow.Attribute, PathToDataOfAnalyticsBeingChecked));
										Items[ColumnName].ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
										AddedCommunicationParametersByOwner = True;
										Break;
									EndIf;
								EndDo;
							EndDo;
						EndIf;
					EndDo;
					AddedCompanyCommunicationParameters = False;
					For Each Type In Items[ColumnName].TypeRestriction.Types() Do
						If AddedCompanyCommunicationParameters Then
							Break;
						EndIf;
						If ComplianceByOrganization[Type] <> Undefined Then
							If AddedCommunicationParametersByOwner Then
								ChoiceParameterLinks = New Array(Items[ColumnName].ChoiceParameterLinks);
							Else
								ChoiceParameterLinks = New Array;
							EndIf;
							If ByCompanies Then
								ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter." + ComplianceByOrganization[Type],
								"Items.BalanceOfEstimate.CurrentData.Organization"));
							EndIf;
							Items[ColumnName].ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
							AddedCompanyCommunicationParameters = True;
						EndIf;
					EndDo;
				EndIf;
			Else
				Items[ColumnName].Visible = False;
				Items[ColumnName].TypeRestriction = New TypeDescription;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPropertiesOfBudgetIndicator()
	
	If ValueIsFilled(Object.BudgetBalanceItem) Then
		TypesOfIndicatorAnalytics = BudgetingServer.DimensionKinds(Object.BudgetBalanceItem, True);
		IndicatorParameters = Common.ObjectAttributesValues(Object.BudgetBalanceItem,
			"RecordByQuantity, RecordByCurrency, DimensionCurrencies, DimensionAddressCurrency");
		If ValueIsFilled(IndicatorParameters.DimensionCurrencies) Then
			IndicatorParameters.Insert("CurrencyFilling", Common.ObjectAttributeValue(
			IndicatorParameters.DimensionCurrencies, "CurrencyFilling"));
		EndIf;
	Else
		IndicatorParameters = New Structure("RecordByQuantity, RecordByCurrency, DimensionCurrencies, DimensionAddressCurrency, CurrencyFilling",
			False, False, Undefined);
		TypesOfIndicatorAnalytics = Undefined;
	EndIf;
	FillPropertyValues(ThisObject, IndicatorParameters);
	
EndProcedure

&AtServer
Procedure OnChangesInBudgetIndicator()
	
	FillInPropertiesOfBudgetIndicator();
	
	Object.BalanceOfEstimate.Clear();
	
	SetColumnPropertiesByCalculatedIndicator();

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateCurrency.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateAmountInCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RecordByCurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DimensionCurrencies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RecordByQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateOrganization.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByCompanies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByBusinessUnits");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateAmountInCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BalanceOfEstimate.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateSumMan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DimensionCurrencies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BalanceOfEstimate.AmountInCurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfEstimateSumCompl.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DimensionCurrencies");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BalanceOfEstimate.AmountInCurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure EnterActualDataBoundaryToFillInBalances(AdditionalParameters)
	
	FormParameters = New Structure("BudgetProfile, BeginOfPeriod, ActualDataLimit", Undefined, Object.DateOfRemainingGoods-1, Object.DateOfRemainingGoods-1);
	CallbackDescription = New CallbackDescription("AfterEnteringActualDataBoundary", ThisObject, AdditionalParameters);
	OpenForm("CommonForm.ConfigureActualDataLimit", FormParameters,,,,, CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterEnteringActualDataBoundary(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AdditionalParameters.Insert("ActualDataLimit", Result);
		FillBalanceServer(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillBalanceCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If AdditionalParameters.Property("ActualDataLimit") Then
			FillBalanceServer(AdditionalParameters);
		Else
			EnterActualDataBoundaryToFillInBalances(AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillBalanceServer(FillParameters)
	
	PopulationSettings = New DataCompositionSettings;
	FinancialReportingServer.NewFilter(PopulationSettings.Filter, "BudgetBalanceItem", Object.BudgetBalanceItem);
	FinancialReportingServer.NewFilter(PopulationSettings.Filter, "Scenario", Object.Scenario);
	
	TempTablesManager = New TempTablesManager;
	
	BoundaryOfResidues = FillParameters.ActualDataLimit;
	CalculateFactBasedOnBudgetIndicator = FillParameters.Property("ActualDataLimit") And ValueIsFilled(
		BoundaryOfResidues);
	If Not CalculateFactBasedOnBudgetIndicator Then
		BalanceParameters = New Structure;
		BalanceParameters.Insert("DateOfRemainingGoods", Object.DateOfRemainingGoods);
		BalanceParameters.Insert("ReportSettings", PopulationSettings);
		BalanceParameters.Insert("ByCompanies", ByCompanies);
		BalanceParameters.Insert("ByBusinessUnits", ByBusinessUnits);
		BalanceParameters.Insert("BalancesForSpecificDate", False);
		BalanceParameters.Insert("SelectionSet", True);
		BalanceParameters.Insert("DataLayoutSelectionIsSet", False);
		BalanceParameters.Insert("FunctionalCurrency", Undefined);
		InformationRegisters.OpeningBalanceOfEstimates.GenerateTemporaryTables_ActualOpeningBalancesOfCalculatedIndicators(
			TempTablesManager, BalanceParameters);
		IndicatorLine_ = TempTablesManager.Tables.Find("CurrentBalanceDates").GetData();
		If Not IndicatorLine_.IsEmpty() Then
			BoundaryOfResidues = IndicatorLine_.Unload()[0].DateOfRemainingGoods-1;
		Else
			BoundaryOfResidues = BegOfYear(Object.DateOfRemainingGoods-1);
			CalculateFactBasedOnBudgetIndicator = True;
			TMCommonUse.DestroyTemporaryTables(TempTablesManager);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
 	If CalculateFactBasedOnBudgetIndicator Then
		FactGettingParameters = ParametersForGettingFactBasedOnFillingSettings();
		BalancesByBudgetIndicator = BudgetingServer.FactOnBudgetIndicators(PopulationSettings,
			FactGettingParameters, TempTablesManager, "BalancesAccordingToCalculatedIndicators");
	EndIf;
	
	ThereArePlannedTurnover = False;
	If BegOfDay(BoundaryOfResidues) < BegOfDay(Object.DateOfRemainingGoods-1) Then
	
		ScriptCourseData = New Structure;
		ScriptCourseData.Insert("ActualDataLimit", BoundaryOfResidues);
		ScriptCourseData.Insert("ScenarioCourseTable", GetFromTempStorage(AddressOfScriptCourseTable));
		
		CalculatePlannedTurnoverByInfluencingBudgetItems(PopulationSettings, BoundaryOfResidues, TempTablesManager,
			ScriptCourseData);
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		ThereArePlannedTurnover = TempTablesManager.Tables.Find("PlannedTurnover") <> Undefined
			And FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, New Array, "PlannedTurnover");
		If ThereArePlannedTurnover And RecordByCurrency Then
			ConvertBalancesFromCurrencyToCurrency = FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query,
				New Array, "BalancesAccordingToCalculatedIndicators");
			If ConvertBalancesFromCurrencyToCurrency Then
				// It is necessary to recalculate the amounts in the currencies of regulated and management accounting, since Balances and turnover
				// could be calculated at different rates as of the date of the Balances (actual and forecast)
				DataTableParameters = BudgetingServer.ParametersForConvertingDataTableToCurrency();
				DataTableParameters.TempTablesManager = TempTablesManager;
				DataTableParameters.TempTableName = "BalancesAccordingToCalculatedIndicators";
				BudgetingServer.ConvertDataTableToCurrency(DataTableParameters, Undefined,
					Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal, , ScriptCourseData);
			EndIf;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	BalancesByBudgetIndicator = TempTablesManager.Tables.Find("BalancesAccordingToCalculatedIndicators").GetData().Unload();
	If ThereArePlannedTurnover Then
		TMCommonUseClientServer.SupplementTable(TempTablesManager.Tables.Find(
			"PlannedTurnover").GetData().Unload(), BalancesByBudgetIndicator);
	EndIf;
	
	CollapseBalanceTableBeforeLoading(BalancesByBudgetIndicator);
	
	Object.BalanceOfEstimate.Load(BalancesByBudgetIndicator);
	
EndProcedure

&AtServer
Procedure CalculatePlannedTurnoverByInfluencingBudgetItems(PopulationSettings, BoundaryOfResidues,
	TempTablesManager, ScriptCourseData)
	
	RulesForCalculatingIndicator = BudgetingServer.GetRulesForCalculatingBudgetMetrics(PopulationSettings);
	RequestAccordingToCalculationRules = BudgetingServer.GenerateRequestToDataSourceAccordingToCalculationRules(
		RulesForCalculatingIndicator.UnloadColumn("CalculationRule"), "Plan");
	QueryText = RequestAccordingToCalculationRules.QueryText;
	If IsBlankString(QueryText) Then
		Return;
	EndIf;
	
	FieldsExcludedFromRequest = New Array;
	FieldsExcludedFromRequest.Add("DayPeriod");
	FieldsExcludedFromRequest.Add("PlanningPeriod");
	FieldsExcludedFromRequest.Add("BudgetFlowItem");
	If Not ByCompanies Then
		FieldsExcludedFromRequest.Add("Organization");
	EndIf;
	If Not ByBusinessUnits Then
		FieldsExcludedFromRequest.Add("Department");
	EndIf;
	
	TemplateForTextOfExcludedField = "AliasOfSourceTable.%1 AS %2";
	TemplateForTextOfFieldToBeAdded = "UNDEFINED AS %1";
	For Each ExcludedField In FieldsExcludedFromRequest Do
		TextOfExcludedField = StringFunctionsClientServer.SubstituteParametersToString(TemplateForTextOfExcludedField, ExcludedField, ExcludedField);
		TextOfFieldToAdd = StringFunctionsClientServer.SubstituteParametersToString(TemplateForTextOfFieldToBeAdded, ExcludedField);
		QueryText = StrReplace(QueryText, TextOfExcludedField, TextOfFieldToAdd);
	EndDo;
	
	TemplateForTextOfExcludedField = "AliasOfSourceTable.Dimension%1 AS Dimension%1Source1";
	TemplateForTextOfFieldToBeAdded = "UNDEFINED AS Dimension%1Source1";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfExcludedField = StringFunctionsClientServer.SubstituteParametersToString(TemplateForTextOfExcludedField, DimensionNumber);
		TextOfFieldToAdd = StringFunctionsClientServer.SubstituteParametersToString(TemplateForTextOfFieldToBeAdded, DimensionNumber);
		QueryText = StrReplace(QueryText, TextOfExcludedField, TextOfFieldToAdd);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&SourceTableConditionsAndAlignmentFields",
		"Scenario = &Scenario AND Status = VALUE(Enum.PlanStatuses.Upholded)");
	QueryText = StrReplace(QueryText, "{&UpdateDate}", "&UpdateDate");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	Data.BudgetBalanceItem AS BudgetBalanceItem,
	|	Data.Scenario AS Scenario,
	|	&TextOfOrganizationField,
	|	&TextOfDivisionField,
	|	CASE
	|		WHEN &RecordByCurrency
	|			THEN &FieldTextCurrency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS Currency,
	|	CASE
	|		WHEN &RecordByCurrency
	|			THEN Data.Currency
	|		ELSE &CurrencyOfMan
	|	END AS StorageCurrency,
	|	&TextOfDimensionsFields,
	|	Data.CountTurnover * CASE WHEN Data.Expense THEN -1 ELSE 1 END AS Count,
	|	CASE
	|		WHEN &RecordByCurrency
	|			THEN Data.AmountInCurrencyTurnover
	|		ELSE Data.SumManTurnover
	|	END * CASE WHEN Data.Expense THEN -1 ELSE 1 END AS AmountInStorageCurrency,
	|	Data.SumManTurnover * CASE WHEN Data.Expense THEN -1 ELSE 1 END AS SumMan,
	|	Data.SumComplTurnover * CASE WHEN Data.Expense THEN -1 ELSE 1 END AS SumCompl,
	|	&RatePeriod AS RatePeriod
	|INTO PlannedTurnover
	|FROM
	|	Data AS Data";
	ArrayOfAnalystFields = New Array;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		ArrayOfAnalystFields.Add(StringFunctionsClientServer.SubstituteParametersToString("Data.Dimension%1",
			DimensionNumber));
	EndDo;
	Query.Text = StrReplace(Query.Text, "&TextOfDimensionsFields", StrConcat(ArrayOfAnalystFields, "," + Chars.LF
		+ Chars.Tab));
	If ValueIsFilled(IndicatorParameters.DimensionAddressCurrency) Then
		TypesOfCurrencyAnalytics = TypesOfIndicatorAnalytics[StringFunctionsClientServer.SubstituteParametersToString(
			"DimensionKind%1ValueType", IndicatorParameters.DimensionAddressCurrency)].Types();
		ArrayOfCurrencyExpressions = New Array;
		CurrencyExpressionTemplate = "WHEN VALUETYPE(Data.Dimension%1) = TYPE(%2)
			|	THEN CAST (Data.Dimension%1 AS %2).%3"; // @query-part
		For Each TypeOfCurrencyAnalytics In TypesOfCurrencyAnalytics Do
			ArrayOfCurrencyExpressions.Add(StringFunctionsClientServer.SubstituteParametersToString(CurrencyExpressionTemplate,
			IndicatorParameters.DimensionAddressCurrency, FinancialAccountingByBalanceSheetRegisterData.FullTypeName(
			TypeOfCurrencyAnalytics), IndicatorParameters.CurrencyFilling));
		EndDo;
		FieldTextCurrency = StringFunctionsClientServer.SubstituteParametersToString("CASE %1 END", StrConcat(
			ArrayOfCurrencyExpressions, Chars.LF + Chars.Tab));
	Else
		FieldTextCurrency = "Data.Currency";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FieldTextCurrency", FieldTextCurrency);
	If ByCompanies Then
		Query.Text = StrReplace(Query.Text, "&TextOfOrganizationField", "Data.Organization AS Organization");
	Else
		Query.Text = StrReplace(Query.Text, "&TextOfOrganizationField,", "");
	EndIf;
	If ByBusinessUnits Then
		Query.Text = StrReplace(Query.Text, "&TextOfDivisionField", "Data.Department AS Department");
	Else
		Query.Text = StrReplace(Query.Text, "&TextOfDivisionField,", "");
	EndIf;
	Query.Text = QueryText + Common.QueryBatchSeparator() + Query.Text;
	
	For Each QueryParameter In RequestAccordingToCalculationRules.QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	Query.SetParameter("UpdateDate", Object.Date);
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("ExpressionStartOfPeriod", EndOfDay(BoundaryOfResidues) + 1);
	Query.SetParameter("ExpressionEndOfPeriod", Object.DateOfRemainingGoods-1);
	Query.SetParameter("RecordByCurrency", IndicatorParameters.RecordByCurrency);
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("RatePeriod", Object.DateOfRemainingGoods);
	
	Query.Execute();
	
	DataTableParameters = BudgetingServer.ParametersForConvertingDataTableToCurrency();
	DataTableParameters.TempTablesManager = Query.TempTablesManager;
	DataTableParameters.TempTableName = "PlannedTurnover";
	BudgetingServer.ConvertDataTableToCurrency(DataTableParameters, Undefined,
		Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal, , ScriptCourseData);
	
EndProcedure

&AtServer
Function ParametersForGettingFactBasedOnFillingSettings()
	
	FactGettingParameters = BudgetingServer.TemplateForGettingFactParameters();
	
	FactGettingParameters.BalancesOnlyAtBeginningOfPeriod = True;
	FactGettingParameters.Period = New StandardPeriod(Object.DateOfRemainingGoods, Object.DateOfRemainingGoods);
	
	FactGettingParameters.ByCompanies = ByCompanies;
	FactGettingParameters.ByBusinessUnits = ByBusinessUnits;
	
	Return FactGettingParameters;

EndFunction

&AtServer
Procedure CollapseBalanceTableBeforeLoading(BalanceTable)
	
	GroupingColumns = New Array;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		GroupingColumns.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
	EndDo;
	If BalanceTable.Columns.Find("Organization") <> Undefined Then
		GroupingColumns.Add("Organization");
	EndIf;
	If BalanceTable.Columns.Find("Department") <> Undefined Then
		GroupingColumns.Add("Department");
	EndIf;
	GroupingColumns.Add("Currency");
	TotalingColumns = "Count,AmountInCurrency,SumMan,SumCompl";
	BalanceTable.GroupBy(StrConcat(GroupingColumns, ","), TotalingColumns);
	
	EmptyStringSearchStructure = New Structure(TotalingColumns, 0,0,0,0);
	TMCommonUse.FindAndDeleteRowsInValueTable(BalanceTable, EmptyStringSearchStructure);
	
EndProcedure

&AtServer
Procedure PlaceScriptCourseTableInTemporaryStorage()
	
	ScenarioCourseTable = Catalogs.BudgetingScenarios.ScenarioCourseTable(Object.Scenario, ,
		BegOfYear(CurrentSessionDate()), Object.DateOfRemainingGoods-1);
	AddressOfScriptCourseTable = PutToTempStorage(ScenarioCourseTable, UUID);
	
EndProcedure

&AtServer
Function GetCurrencyFromAnalyticsValue(DimensionValue)
	
	CacheAnalystValues = GetFromTempStorage(AddressOfAnalyticsValueCache);
	Currency = BudgetReportingDisplayServer.Attachable_ValueFromAnalytics(CacheAnalystValues,
		DimensionValue, IndicatorParameters.CurrencyFilling);
	AddressOfAnalyticsValueCache = PutToTempStorage(CacheAnalystValues, UUID);
	
	Return Currency;
	
EndFunction

&AtServer
Procedure RecalculateManAndLocalAmountsInRowOfTablePart(RowID, RecalculateAmountMAN, RecalculateLocalAmount)
	
	LineOfATabularSection = Object.BalanceOfEstimate.FindByID(RowID);
	
	BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	
	CurrencyExchangeRateCache = GetFromTempStorage(AddressOfCurrencyExchangeRateCache);
	NumberOfCacheEntries = CurrencyExchangeRateCache.Count();
	
	If ValueIsFilled(LineOfATabularSection.Currency) Then
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(LineOfATabularSection.Currency, Object.DateOfRemainingGoods,
			CurrencyExchangeRateCache, BaseCurrency);
	EndIf;
	
	If RecalculateAmountMAN Or Not ValueIsFilled(LineOfATabularSection.Currency) Then
		ManSExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(CurrencyOfManAccounting, Object.DateOfRemainingGoods, CurrencyExchangeRateCache,
			BaseCurrency);
	EndIf;
	If RecalculateAmountMAN Then
		LineOfATabularSection.SumMan = ?(ManSExchangeRate = 0, 0, LineOfATabularSection.AmountInCurrency * CurrencyExchangeRate / ManSExchangeRate);
	EndIf;
	
	If RecalculateLocalAmount Then
		If ByCompanies And ValueIsFilled(LineOfATabularSection.Organization) Then
			LocalCurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
				SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(
				LineOfATabularSection.Organization), Object.DateOfRemainingGoods, CurrencyExchangeRateCache, BaseCurrency);
		Else
			LocalCurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(CurrencyOfComplianceAccounting, Object.DateOfRemainingGoods,
				CurrencyExchangeRateCache, BaseCurrency);
		EndIf;
		LineOfATabularSection.SumCompl = ?(LocalCurrencyExchangeRate = 0, 0, LineOfATabularSection.AmountInCurrency * ?(ValueIsFilled(
			LineOfATabularSection.Currency), CurrencyExchangeRate, ManSExchangeRate) / LocalCurrencyExchangeRate);
	EndIf;
	
	If CurrencyExchangeRateCache.Count() > NumberOfCacheEntries Then
		PutToTempStorage(CurrencyExchangeRateCache, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsOfMenSAndLocalSByForecastRatesInRowOfTablePart(RowID, RecalculateAmountMAN, RecalculateLocalAmount)
	
	LineOfATabularSection = Object.BalanceOfEstimate.FindByID(RowID);
	
	ScenarioCourseTable = GetFromTempStorage(AddressOfScriptCourseTable);
	
	If ValueIsFilled(LineOfATabularSection.Currency) Then
		RowOfCourseTable = ScenarioCourseTable.Find(LineOfATabularSection.Currency, "Currency");
		CurrencyExchangeRate = ?(RowOfCourseTable = Undefined, 0, RowOfCourseTable.Rate);
	EndIf;
	
	If RecalculateAmountMAN Or Not ValueIsFilled(LineOfATabularSection.Currency) Then
		RowOfCourseTable = ScenarioCourseTable.Find(CurrencyOfManAccounting, "Currency");
		ManSExchangeRate = ?(RowOfCourseTable = Undefined, 0, RowOfCourseTable.Rate);
	EndIf;
	If RecalculateAmountMAN Then
		LineOfATabularSection.SumMan = ?(ManSExchangeRate = 0, 0, LineOfATabularSection.AmountInCurrency * CurrencyExchangeRate / ManSExchangeRate);
	EndIf;
	
	If RecalculateLocalAmount Then
		If ByCompanies And ValueIsFilled(LineOfATabularSection.Organization) Then
			RowOfCourseTable = ScenarioCourseTable.Find(
				SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(
				LineOfATabularSection.Organization), "Currency");
		Else
			RowOfCourseTable = ScenarioCourseTable.Find(CurrencyOfComplianceAccounting, "Currency");
		EndIf;
		LocalCurrencyExchangeRate = ?(RowOfCourseTable = Undefined, 0, RowOfCourseTable.Rate);
		LineOfATabularSection.SumCompl = ?(LocalCurrencyExchangeRate = 0, 0, LineOfATabularSection.AmountInCurrency * ?(ValueIsFilled(
			LineOfATabularSection.Currency), CurrencyExchangeRate, ManSExchangeRate) / LocalCurrencyExchangeRate);
	EndIf;
	
EndProcedure

&AtServer
Function LineDuplicatesExistingOne(CurrentRow, DoubleLineNumber)
	
	TableRow = Object.BalanceOfEstimate.FindByID(CurrentRow);
	
	SearchColumns = StrSplit("Organization,Department,Currency", ",");
	For DimensionNumber = 1 To BudgetingClientServer.MaximumNumberOfAnalysts() Do
		SearchColumns.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
	EndDo;
	TheStructureOfTheSearch = New Structure;
	For Each Column In SearchColumns Do
		TheStructureOfTheSearch.Insert(Column, TableRow[Column]);
	EndDo;
	
	FoundRows = Object.BalanceOfEstimate.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		If FoundRow <> TableRow Then
			DoubleLineNumber = FoundRow.LineNumber;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

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
