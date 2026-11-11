#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var Percent;

#EndRegion

#Region Internal

Procedure UpdateDataOnNegativeBalancesAndBalances() Export
	
	NumberOfPositionsNegativeBalance       = 0;
	NumberOfPositionsNegativeBalanceOther = 0;
	ItemQuantitySidedBalance          = 0;
		
	If ValueIsFilled(MonthOfCorrection) Then
		Query           = RequestingNumberOfProblemPositions();
		QueryResult = Query.ExecuteBatch(); 		
		UBound         = QueryResult.UBound();
		
		SelectionDetailRecords = QueryResult[UBound - 2].Select();
		If SelectionDetailRecords.Next() Then
			TotalProblemPositions = SelectionDetailRecords.NumberOfRows;
		EndIf;
		
		SelectionDetailRecords = QueryResult[UBound - 1].Select();
		If SelectionDetailRecords.Next() Then
			NumberOfPositionsNegativeBalance = SelectionDetailRecords.NumberOfRows;
		EndIf;
		SelectionDetailRecords = QueryResult[UBound].Select();
		If SelectionDetailRecords.Next() Then
			NumberOfPositionsNegativeBalanceOther = SelectionDetailRecords.NumberOfRows;
		EndIf;
		ItemQuantitySidedBalance = TotalProblemPositions - NumberOfPositionsNegativeBalance;
	EndIf;
	
EndProcedure

Procedure FillInMonthOfCorrection() Export

	MonthOfCorrection                          = Undefined;
	NumberOfPositionsNegativeBalanceBefore = 0;
	ItemQuantitySidedBalanceBeforeCorrection    = 0;
	
	PeriodRequestTexts = New Array;
	
	QueryTextPeriodTemplate =
		"SELECT
		|	&TemplatePeriod 										AS Period,
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&TemplatePeriodBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	&TemplatePeriod 										AS Period,
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &TemplatePeriod
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	&TemplatePeriod 												AS Period,
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&TemplatePeriodBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes)) AS CompanySafeStockBalance";

	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CompanyGoods.Period AS Period
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|
		|ORDER BY
		|	Period";
	
	QueryResult       = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		
		EndOfTheCurrentMonth = EndOfMonth(CurrentSessionDate());
		ThreeYearsAgo        = EndOfMonth(AddMonth(EndOfTheCurrentMonth, -36));
		
		SectionsToCheck = New Array;
		SectionsToCheck.Add("RoutineOperations");
		SectionsToCheck.Add("Bookkeeping");
		
		DataTable = PeriodClosingDates.DataToCheckTemplate();
		For Each CurrentSection In SectionsToCheck Do
			NewRow        = DataTable.Add();
			NewRow.Date   = ThreeYearsAgo;
			NewRow.Section = CurrentSection;
		EndDo;
		
		DataDetails = New Structure("NewVersion, Data", False, "");
		ErrorDescription = New Structure;
		PeriodEndClosingDate	   = Date(1,1,1); // the first permitted period
		
		ChangesAreDisabled = PeriodClosingDates.PeriodEndClosingFound(DataTable, DataDetails, ErrorDescription);		
		If ChangesAreDisabled Then
			For Each BanLine In ErrorDescription.PeriodEnds Do
				CurBan = EndOfMonth(BanLine.PeriodEndClosingDate) + 1;
				
				If Not ValueIsFilled(PeriodEndClosingDate) Then
					PeriodEndClosingDate = CurBan;
				Else
					PeriodEndClosingDate = Max(PeriodEndClosingDate, CurBan);
				EndIf;
			EndDo;
		EndIf;
		
		ThreeYearsAgo = EndOfMonth(Max(ThreeYearsAgo, Min(PeriodEndClosingDate, EndOfTheCurrentMonth)));
		CurMonth     = Max(EndOfMonth(SelectionDetailRecords.Period), ThreeYearsAgo);
		
		While CurMonth <= EndOfTheCurrentMonth Do
			QueryText = QueryTextPeriodTemplate;
			QueryText = StrReplace(QueryText, "TemplatePeriodBoundary", "PeriodBoundary" + Format(CurMonth, "DF=yyyyMM"));
			QueryText = StrReplace(QueryText, "TemplatePeriod", "Period" + Format(CurMonth, "DF=yyyyMM"));
			PeriodRequestTexts.Add(QueryText);

			Query.SetParameter("PeriodBoundary" + Format(CurMonth, "DF=yyyyMM"), New Boundary(CurMonth, BoundaryType.Including));
			Query.SetParameter("Period" + Format(CurMonth, "DF=yyyyMM"), CurMonth);

			CurMonth = EndOfMonth(AddMonth(CurMonth, 1));
		EndDo;
		Query.SetParameter("Period" + Format(CurMonth, "DF=yyyyMM"), CurMonth);
		
		TempTablesManager	= New TempTablesManager;
		DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
		Query.TempTablesManager = TempTablesManager;
		Query.Text = 
			InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&Period" + Format(CurMonth, "DF=yyyyMM")) + 
			Common.QueryBatchSeparator() +
			
			"SELECT
			|	NestedQuery.Period 						AS Period,
			|	NestedQuery.Organization 				AS Organization,
			|	NestedQuery.ItemsLocationAttributes 	AS ItemsLocationAttributes,
			|	NestedQuery.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
			|	NestedQuery.CCDNumber 					AS CCDNumber,
			|	SUM(NestedQuery.CountBalance) 	AS CountBalance
			|INTO BalancesAtEndOfPeriod
			|FROM
			|	QueryTextPeriods AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.Period,
			|	NestedQuery.Organization,
			|	NestedQuery.ItemsLocationAttributes,
			|	NestedQuery.InventoryOwnerAttribute,
			|	NestedQuery.CCDNumber
			|
			|INDEX BY
			|	Period,
			|	Organization,
			|	ItemsLocationAttributes,
			|	InventoryOwnerAttribute,
			|	CCDNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP CompanyGoodsOnWay
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	BalancesAtEndOfPeriod.Period AS Period
			|FROM
			|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
			|
			|GROUP BY
			|	BalancesAtEndOfPeriod.Period,
			|	BalancesAtEndOfPeriod.Organization,
			|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
			|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
			|	BalancesAtEndOfPeriod.CCDNumber
			|
			|HAVING
			|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
			|
			|ORDER BY
			|	Period
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP BalancesAtEndOfPeriod";
		
		Query.Text = StrReplace(
			Query.Text, 
			"QueryTextPeriods", 
			"(" + StrConcat(PeriodRequestTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		
		MonthOfCorrection = EndOfMonth(CurrentSessionDate());
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			SelectionDetailRecords = QueryResult.Select();
			While SelectionDetailRecords.Next() Do
				If SelectionDetailRecords.Period >= ThreeYearsAgo Then
					MonthOfCorrection = SelectionDetailRecords.Period;
					Break;
				EndIf;
			EndDo;
		 
			Query           = RequestingNumberOfProblemPositions();
			QueryResult = Query.ExecuteBatch();
			UBound         = QueryResult.UBound();
			
			SelectionDetailRecords = QueryResult[UBound - 2].Select();
			If SelectionDetailRecords.Next() Then
				TotalProblemPositions = SelectionDetailRecords.NumberOfRows;
			EndIf;
			
			SelectionDetailRecords = QueryResult[UBound - 1].Select();
			If SelectionDetailRecords.Next() Then
				NumberOfPositionsNegativeBalanceBefore = SelectionDetailRecords.NumberOfRows;
			EndIf;
			
			ItemQuantitySidedBalanceBeforeCorrection = TotalProblemPositions - NumberOfPositionsNegativeBalanceBefore;
		EndIf;

	EndIf;
	
EndProcedure

Procedure CreateNewReserves(NewSettings_ = False) Export
	
	If Constants.ControlCompanyStockBalance.Get() Then
		SessionParameters.PostWithoutControlOfCompanyStockBalance = True;
	EndIf;
	
	ClearReserves("Negative_Balance");
	
	TempTablesManager = New TempTablesManager;
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance,
		|	CompanyGoodsBalance.QuantityByGBRNBalance 	AS QuantityByGBRNBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance,
		|	0													AS QuantityByGBRNBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes AS TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance,
		|	CompanySafeStockBalance.QuantityByGBRNBalance 	AS QuantityByGBRNBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt) 				AS RecordType,
		|	&MonthOfCorrection 									AS Period,
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 						AS CCDNumber,
		|	FALSE 												AS ReversingEntry,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 		AS Count,
		|	CASE
		|		WHEN NOT &UseTraceableImportedGoodsAccounting
		|				OR BEGINOFPERIOD(&MonthOfCorrection, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
		|			THEN 0
		|		ELSE SUM(BalancesAtEndOfPeriod.QuantityByGBRNBalance)
		|	END 												AS QuantityByGBRN
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod";
	
	Query.SetParameter("MonthOfCorrection",   MonthOfCorrection);
	Query.SetParameter("CorrectionBoundary", New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",  EndOfMonth(MonthOfCorrection));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryResult = Query.Execute();
	
	Companies = QueryResult.Unload().UnloadColumn("Organization");
	Companies = CommonClientServer.CollapseArray(Companies);
	
	HadErrors = False;
	
	For Each Organization In Companies Do
		
		TableProductsOfOrganizations	= QueryResult.Unload();
		MaximumTableIndex	= TableProductsOfOrganizations.Count() - 1;
		
		For Counter = 0 To MaximumTableIndex Do
			Page1 = TableProductsOfOrganizations[MaximumTableIndex - Counter];
			
			If Page1.Organization <> Organization Then
				TableProductsOfOrganizations.Delete(Page1);
			EndIf;
		EndDo;
		
		DocumentObject = New Structure;
		DocumentObject.Insert("Ref",      Undefined);
		DocumentObject.Insert("Date",        MonthOfCorrection);
		DocumentObject.Insert("Organization", Organization);
		DocumentObject.Insert("RegisterRecords",    New Structure);

		DocumentObject.RegisterRecords.Insert("CompanyGoods", TableProductsOfOrganizations);
		DocumentObject.RegisterRecords.Insert("CompanySafeStock");
		
		DocumentObject.Insert("AdditionalProperties", New Structure);
		DocumentObject.AdditionalProperties.Insert("ItIsNecessaryToControlRemnantsOfGoods", 		 True);
		DocumentObject.AdditionalProperties.Insert("ItIsNecessaryToFormStornoOnReservesOfGoods", False);
		DocumentObject.AdditionalProperties.Insert("BeginningOfPeriodForCorrectingBalances",          BegOfMonth(MonthOfCorrection));
		DocumentObject.AdditionalProperties.Insert("EndOfPeriodForCorrectingBalances",       EndOfMonth(MonthOfCorrection));
		DocumentObject.AdditionalProperties.Insert("RefillInventoryKinds", 							 True);
		
		ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
		ParametersForFillingInventoryTypes.DocumentMakesBothArrivalAndExpenditure = True;
		
		BeginTransaction();
		
		Try
			Cancel = False;			
			TempTablesManager = New TempTablesManager;
			
			InventoriesServer.PrepareRecordOfBusinessProducts(DocumentObject,
															TempTablesManager,
															DocumentWriteMode.Posting,
															ParametersForFillingInventoryTypes);
			
			InventoriesServer.CreateReservesForGoodsOfOrganizations(DocumentObject,
																TempTablesManager,
																Cancel,
																ParametersForFillingInventoryTypes);
			
			NameOfOrganizationSProductReservesTable = InventoriesServer.NameOfOrganizationSProductReservesTable();
			
			If DocumentObject.AdditionalProperties.Property(NameOfOrganizationSProductReservesTable)
				 And DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable].Count() Then
				SetPrivilegedMode(True);
				
				CommentTemplate = NStr(
				"vi = 'Đã tự động tạo chứng từ từ trợ giúp chỉnh sửa số dư hàng hóa của doanh nghiệp %CurrentSessionDate%';
				|ru = 'Документ сформирован автоматически из помощника исправления остатков товаров организаций %CurrentSessionDate%';
				|en = 'Document is generated automatically from the wizard of correcting company stock balance %CurrentSessionDate%'; fa = 'Document is generated automatically from the wizard of correcting company stock balance %CurrentSessionDate%';
				|it = 'Il documento è generato automaticamente dall''assistente di rettifica delle rimanenze merci delle società %CurrentSessionDate%';
				|pl = 'Dokument został sformowany automatycznie, z asystenta korekty pozostałości towarów firmy %CurrentSessionDate%';
				|tr = 'Belge, %CurrentSessionDate% iş yerlerinin ürün bakiyesinin düzeltilmesi sihirbazından otomatik olarak oluşturuldu'");
				
				RegisterAdjustment = Documents.RegisterAdjustment.CreateDocument();
				RegisterAdjustment.Date = CurrentSessionDate();
				RegisterAdjustment.EmployeeResponsible = Users.CurrentUser();
				RegisterAdjustment.Comment = StrReplace(CommentTemplate, "%CurrentSessionDate%", Format(CurrentSessionDate(), "DLF=DDT"));
				
				NewRow = RegisterAdjustment.RegistersTable.Add();
				NewRow.Name = "CompanySafeStock";
				RegisterAdjustment.Write();
				
				Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
				Set.Load(DocumentObject.AdditionalProperties[NameOfOrganizationSProductReservesTable]);
				Set.Filter.Recorder.Set(RegisterAdjustment.Ref);
				Set.Write();
				
				SetPrivilegedMode(False);
				
				If NewSettings_ Then
					ReserveAdjustmentsByNewSettings.Add().Document = RegisterAdjustment.Ref;
				Else
					ReserveAdjustments.Add().Document = RegisterAdjustment.Ref;
				EndIf;
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			
			HadErrors = True;
			DetailErrorDescription = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName(),
									EventLogLevel.Error,
									Metadata.DataProcessors.WizardOfCorrectingCompanyStockBalance,
									,
									DetailErrorDescription);
		EndTry;
	EndDo;
	
	If HadErrors Then
		MessageText = NStr("vi = 'Khi tạo lại dự phòng hàng hóa của doanh nghiệp đã xảy ra lỗi. Chi tiết trong nhật ký sự kiện.';
							|ru = 'При переформировании резервов товаров организации возникли ошибки. Подбробности в журнале регистрации.';
							|en = 'Errors occurred when rebuilding company goods reserves. For more information, see the event log.'; fa = 'Errors occurred when rebuilding company goods reserves. For more information, see the event log.';
							|it = 'Durante la rigenerazione delle scorte merci della società, si sono verificati degli errori. Dettagli nel registro.';
							|pl = 'Podczas refirmy rezerwy towarów firmy wynikły błędy. Szczegóły w dzienniku rejestracji.';
							|tr = 'Bir iş yerinin ürün rezervleri yeniden oluşturulurken hatalar oluştu. Ayrıntılar kayıt defterinde.'");
		
		Raise MessageText;
	EndIf;
	
EndProcedure

Procedure CreateNewReservesForNewSettings() Export
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CreateNewReserves(True);
	
EndProcedure

Procedure GenerateCorrectionsToExpandedBalance() Export
	
	If Constants.ControlCompanyStockBalance.Get() Then
		SessionParameters.PostWithoutControlOfCompanyStockBalance = True;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	
	RequestForOrganizationWithNegativeBalance		= RequestForOrganizationWithNegativeBalance(TempTablesManager,
																							True);
	RequestSourcesOfExpandedBalanceCoverage	= RequestSourcesOfExpandedBalanceCoverage(TempTablesManager);
	
	TypesOfOffsettingBalances = TypesOfOffsetOfBalancesOfExpandedBalance();
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														MonthOfCorrection);
	
	SetPrivilegedMode(True);
	
	ResultOfOrganizationWithNegativeBalance	= RequestForOrganizationWithNegativeBalance.Execute();
	SelectingOrganizationWithNegativeBalance	= ResultOfOrganizationWithNegativeBalance.Select();
	
	While SelectingOrganizationWithNegativeBalance.Next() Do
		
		RequestSourcesOfExpandedBalanceCoverage.SetParameter("Organization",
																	SelectingOrganizationWithNegativeBalance.Organization);
		RequestSourcesOfExpandedBalanceCoverage.SetParameter("InventoryType",
																	SelectingOrganizationWithNegativeBalance.InventoryType);
		
		BeginTransaction();
		
		Try
			
			DocumentObject		= Undefined;
			QueryResult	= RequestSourcesOfExpandedBalanceCoverage.ExecuteBatch();
			
			For Each TypeOfCredit In TypesOfOffsettingBalances Do
				
				TableOfBalancesToDistribution = QueryResult[TypeOfCredit.PackageNumberReadyForDistribution].Unload();
				TableOfBalancesToDistribution.Indexes.Add(TypeOfCredit.TheStructureOfTheSearch);
				
				SamplingNegativeResiduals = QueryResult[TypeOfCredit.PackageNumberNegativeBalances].Select();
				
				While SamplingNegativeResiduals.Next() Do
					
					QuantityRequiredToDistribute = -SamplingNegativeResiduals.Count;
					
					TheStructureOfTheSearch = New Structure(TypeOfCredit.TheStructureOfTheSearch);
					FillPropertyValues(TheStructureOfTheSearch, SamplingNegativeResiduals, TypeOfCredit.TheStructureOfTheSearch);
					
					RowsOfResidualsToDistribution = TableOfBalancesToDistribution.FindRows(TheStructureOfTheSearch);
					
					For Each RemainderLine In RowsOfResidualsToDistribution Do
						
						If Not QuantityRequiredToDistribute Then
							Break;
						EndIf;
						
						// To form reserves, it is required to close the expanded balance by the GTD numbers.
						If RemainderLine.ReserveRequired
							And RemainderLine.CCDNumber = SamplingNegativeResiduals.CCDNumber Then
							
							Continue;
							
						EndIf;
						
						Count			= Min(RemainderLine.Count, QuantityRequiredToDistribute);
						QuantityByGBRN	= ?(UseTraceableImportedGoodsAccounting,
												?(RemainderLine.Count - Count = 0,
													RemainderLine.QuantityByGBRN,
													Count * RemainderLine.QuantityByGBRN / RemainderLine.Count),
												0);
						
						If DocumentObject = Undefined Then
							DocumentObject = Documents.CorrectionOfSidedBalanceInCompanyGoodsAccounting.CreateDocument();
							DocumentObject.Date				= MonthOfCorrection;
							DocumentObject.Organization		= SamplingNegativeResiduals.Organization;
							DocumentObject.EmployeeResponsible	= Users.CurrentUser();
							
							DocumentObject.AdditionalProperties.Insert("RefillInventoryKinds", True);
							DocumentObject.AdditionalProperties.Insert("BeginningOfPeriodForCorrectingBalances",
																			BegOfMonth(MonthOfCorrection));
							DocumentObject.AdditionalProperties.Insert("EndOfPeriodForCorrectingBalances",
																			EndOfMonth(MonthOfCorrection));
							
							CommentTemplate = NStr("vi = 'Chứng từ được tạo tự động từ trợ giúp sửa số dư của hàng hóa trong các doanh nghiệp %CurrentSessionDate%';
													|ru = 'Документ сформирован автоматически из помощника исправления остатков товаров организаций %CurrentSessionDate%';
													|en = 'Document is generated automatically from the wizard of correcting company stock balance %CurrentSessionDate%'; fa = 'Document is generated automatically from the wizard of correcting company stock balance %CurrentSessionDate%';
													|it = 'Il documento è generato automaticamente dall''assistente di rettifica delle rimanenze merci delle società %CurrentSessionDate%';
													|pl = 'Dokument został sformowany automatycznie, z asystenta korekty pozostałości towarów firmy %CurrentSessionDate%';
													|tr = 'Belge, %CurrentSessionDate% iş yerlerinin ürün bakiyesinin düzeltilmesi sihirbazından otomatik olarak oluşturuldu'");
							
							DocumentObject.Comment = StrReplace(CommentTemplate,
																	"%CurrentSessionDate%",
																	Format(CurrentSessionDate(), "DLF=DDT"));
						EndIf;
						
						TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, InventoryOwnerAttributeGoodsReceipts,
															|WriteOffInventoryAttributes, CCDNumberForReceiving,
															|CCDNumberForWriteOff");
						TheStructureOfTheSearch.ItemsLocationAttributes	= SamplingNegativeResiduals.ItemsLocationAttributes;
						TheStructureOfTheSearch.InventoryOwnerAttributeGoodsReceipts		= SamplingNegativeResiduals.InventoryOwnerAttribute;
						
						If RemainderLine.ReserveRequired Then
							TheStructureOfTheSearch.WriteOffInventoryAttributes = SamplingNegativeResiduals.InventoryOwnerAttribute;
						Else
							TheStructureOfTheSearch.WriteOffInventoryAttributes = RemainderLine.InventoryOwnerAttribute;
						EndIf;
						
						TheStructureOfTheSearch.CCDNumberForReceiving	= SamplingNegativeResiduals.CCDNumber;
						TheStructureOfTheSearch.CCDNumberForWriteOff		= RemainderLine.CCDNumber;
						
						FixLines = DocumentObject.Corrections.FindRows(TheStructureOfTheSearch);
						
						If FixLines.Count() Then
							PatchString = FixLines[0];
						Else
							PatchString = DocumentObject.Corrections.Add();
							FillPropertyValues(PatchString, TheStructureOfTheSearch);
						EndIf;
						
						PatchString.Count		= PatchString.Count + Count;
						PatchString.QuantityByGBRN	= PatchString.QuantityByGBRN + QuantityByGBRN;
						
						RemainderLine.Count		= RemainderLine.Count - Count;
						RemainderLine.QuantityByGBRN	= RemainderLine.QuantityByGBRN - QuantityByGBRN;
						
						QuantityRequiredToDistribute = QuantityRequiredToDistribute - Count;
						
						If RemainderLine.Count = 0 Then
							TableOfBalancesToDistribution.Delete(RemainderLine);
						EndIf;
						
					EndDo;
					
				EndDo;
				
			EndDo;
			
			If DocumentObject <> Undefined Then
				DocumentObject.Write(DocumentWriteMode.Posting);
				
				CorrectionsOfStockBalanceOfCompanies.Add().Document = DocumentObject.Ref;
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			DetailErrorDescription = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName(),
									EventLogLevel.Error,
									Metadata.DataProcessors.WizardOfCorrectingCompanyStockBalance,
									,
									DetailErrorDescription);
			
			MessageText = NStr("vi = 'Không thể tạo bản chỉnh sửa số dư mở rộng. Chi tiết trong nhật ký sự kiện.';
								|ru = 'Не удалось сформировать исправления развернутого сальдо. Подробности в журнале регистрации.';
								|en = 'Cannot generate corrections of detailed balance. See the event log for details.'; fa = 'Cannot generate corrections of detailed balance. See the event log for details.';
								|it = 'Impossibile generare le correzioni del saldo esteso. Dettagli nel registro.';
								|pl = 'Nie udało się sformować korekty rozwiniętego saldo. Szczegóły w dzienniku rejestracji.';
								|tr = 'Başlangıç bakiyesi için düzeltme oluşturulamadı. Ayrıntılar kayıt defterinde.'");
			
			Raise MessageText;
			
		EndTry;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure RefillInventoryKinds() Export
	
	If Constants.ControlCompanyStockBalance.Get() Then
		SessionParameters.PostWithoutControlOfCompanyStockBalance = True;
	EndIf;
	
	End = False;
	Iteration = 1;
	While Not End Do
 		If Iteration > 50 Then
			ExceptionText = NStr("vi = 'Đã vượt quá hạn mức lặp làm đầy các dạng vật tư';
								|ru = 'Превышен лимит итераций перезаполнения видов запасов';
								|en = 'Limit of inventory owner attribute refilling iteration is exceeded'; fa = 'Limit of inventory owner attribute refilling iteration is exceeded';
								|it = 'Limite delle iterazioni per la ricompilazione dei tipi delle scorte è superato';
								|pl = 'Przekroczono limit iteracji ponownego wypełnienia rodzajów zapasów';
								|tr = 'Stok türlerinin aşırı doldurulmasına ilişkin yineleme sınırı aşıldı'", Metadata.DefaultLanguage.LanguageCode);
			WriteLogEvent(
				EventName(),
				EventLogLevel.Error,
				Metadata.DataProcessors.WizardOfCorrectingCompanyStockBalance,
				,
				ExceptionText);
			Raise ExceptionText;
		EndIf;
		
		FillInListOfDocumentsToBeRefilled();
		If DocumentsToRefill.Count() = 0 Then
			If FollowingAnalysisOfUnfoldedBalance() Then
				ClearReserves("ByAnalytics");
				Iteration = 1;
				Continue;
			Else
				End = True;
			EndIf;
		Else
			UncheckInventoryTypesFlagSpecifiedManually();
			ReFillStockTypesIteration();
			Iteration = Iteration + 1;
		EndIf;
		DocumentsToRefill.Clear();
	EndDo;
	
EndProcedure

Procedure FillInNewTransferSettings() Export
	
	NewCustomizationCustomerInvoiceIntercompany.Clear();
	CompaniesForTransferGeneration.Clear();
	FiltersForTransferGeneration.Clear();
	
	TempTablesManager = New TempTablesManager;
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	RequestForOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance(TempTablesManager, False);
	RequestOrganizationSources = RequestOrganizationSources(TempTablesManager, True, True, False, False);
	ResultOfOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance.Execute();
	SelectingOrganizationWithNegativeBalance = ResultOfOrganizationWithNegativeBalance.Select();
	While SelectingOrganizationWithNegativeBalance.Next() Do
		
		RequestOrganizationSources.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
		RequestOrganizationSources.SetParameter("InventoryType", SelectingOrganizationWithNegativeBalance.InventoryType);
		
		OrganizationResultSources = RequestOrganizationSources.Execute();
		
		If Not OrganizationResultSources.IsEmpty() Then
			OrganizationRow = CompaniesForTransferGeneration.Add();
			OrganizationRow.Organization = SelectingOrganizationWithNegativeBalance.Organization;
			OrganizationRow.InventoryType = SelectingOrganizationWithNegativeBalance.InventoryType;
		EndIf;
		
		CurrentCompany = Undefined;
		OrganizationSelectionSources = OrganizationResultSources.Select();
		While OrganizationSelectionSources.Next() Do
			
			If CurrentCompany <> OrganizationSelectionSources.Organization Then
				Setting = NewCustomizationCustomerInvoiceIntercompany.Add();
				Setting.Seller = SelectingOrganizationWithNegativeBalance.Organization;
				Setting.InventoryTypeOfOwner = OrganizationSelectionSources.InventoryType;
				Setting.Owner = OrganizationSelectionSources.Organization;
				CurrentCompany = OrganizationSelectionSources.Organization
			EndIf;
			
			RowSelections = FiltersForTransferGeneration.Add();
			RowSelections.Products = OrganizationSelectionSources.Products;
			RowSelections.Warehouse = OrganizationSelectionSources.Warehouse;
			RowSelections.Organization = SelectingOrganizationWithNegativeBalance.Organization;
			RowSelections.InventoryType = SelectingOrganizationWithNegativeBalance.InventoryType;
			
		EndDo;
		
	EndDo;

EndProcedure

Procedure FillOutOrdersForRegistrationOfRegistrationForms() Export
	
	ReferencesForGeneratingOfGoodsReceipt.Clear();
	DataForFillingReceipts.Clear();
	
	Query = RequestingSelectionsOfProblematicBalances();
	Query.Text = Query.Text + Common.QueryBatchSeparator() +
	"SELECT
	|	DetailedBalance.Organization AS Organization,
	|	DetailedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose,
	|	DetailedBalance.CCDNumber AS CCDNumber,
	|	DetailedBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	-DetailedBalance.CountBalance AS Count
	|FROM
	|	DetailedBalancesAtEndOfMonth AS DetailedBalance
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON DetailedBalance.InventoryOwnerAttribute = InventoryKinds.Ref
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON DetailedBalance.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND InventoryLocationAttributeKeys.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|	AND DetailedBalance.CountBalance < 0
	|
	|UNION ALL
	|
	|SELECT
	|	DetailedBalance.Organization AS Organization,
	|	DetailedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose,
	|	DetailedBalance.CCDNumber AS CCDNumber,
	|	DetailedBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	-DetailedBalance.CountBalance AS Count
	|FROM
	|	DetailedBalancesAtEndOfMonth AS DetailedBalance
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON DetailedBalance.InventoryOwnerAttribute = InventoryKinds.Ref
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON DetailedBalance.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|	AND InventoryLocationAttributeKeys.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|	AND InventoryLocationAttributeKeys.WarehouseArea.ShopFloorStockroom
	|	AND InventoryLocationAttributeKeys.WarehouseArea.Department.ProductionBusinessUnit
	|	AND DetailedBalance.CountBalance < 0
	|
	|ORDER BY
	|	Organization,
	|	Warehouse
	|";
	
	QueryResult = Query.Execute();
	CurrentCompany = Undefined;
	CurrentWarehouse = Undefined;
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		If CurrentCompany <> SelectionDetailRecords.Organization
			Or CurrentWarehouse <> SelectionDetailRecords.Warehouse Then
			RowOrder = ReferencesForGeneratingOfGoodsReceipt.Add();
			RowOrder.Organization = SelectionDetailRecords.Organization;
			RowOrder.Warehouse = SelectionDetailRecords.Warehouse;
			CurrentCompany = SelectionDetailRecords.Organization;
			CurrentWarehouse = SelectionDetailRecords.Warehouse;
		EndIf;
		RowOrder.NumberOfRows = RowOrder.NumberOfRows + 1;
		FillPropertyValues(DataForFillingReceipts.Add(), SelectionDetailRecords);
	EndDo;
	
EndProcedure

Procedure ReFormationOfReservesIsNotRequired() Export
	
	RecalculationOfReservesRequired = False;
	
	TempTablesManager = New TempTablesManager;
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	RequestForOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance(TempTablesManager, True);
	RequestOrganizationSources = RequestOrganizationSources(TempTablesManager, True, True, True, False);
	ResultOfOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance.Execute();
	SelectingOrganizationWithNegativeBalance = ResultOfOrganizationWithNegativeBalance.Select();
	While SelectingOrganizationWithNegativeBalance.Next() Do
		
		RequestOrganizationSources.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
		RequestOrganizationSources.SetParameter("InventoryType", SelectingOrganizationWithNegativeBalance.InventoryType);
		
		QueryResult = RequestOrganizationSources.Execute();
		If Not QueryResult.IsEmpty() Then
			RecalculationOfReservesRequired = True;
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CorrectionOfUnfoldedBalanceIsRequired() Export
	
	SidedBalanceCorrectionIsRequired = False;
	RefillInventoryOwnerAttributes      = False;
	
	TempTablesManager = New TempTablesManager;
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	RequestForOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance(TempTablesManager, True);
	RequestOrganizationSources = RequestOrganizationSources(TempTablesManager, True, False, True, True);
	RequestForCompanySourcesWithoutInventoryTypes = RequestForCompanySourcesWithoutInventoryTypes(TempTablesManager, True, False, True, True);
	
	ResultOfOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance.Execute();
	SelectingOrganizationWithNegativeBalance = ResultOfOrganizationWithNegativeBalance.Select();
	While SelectingOrganizationWithNegativeBalance.Next() Do
		
		RequestOrganizationSources.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
		RequestOrganizationSources.SetParameter("InventoryType", SelectingOrganizationWithNegativeBalance.InventoryType);
		
		QueryResult = RequestOrganizationSources.Execute();
		SelectionDetailRecords = QueryResult.Select();
		If SelectionDetailRecords.Next() Then
			SidedBalanceCorrectionIsRequired = True;
		EndIf;
		
		RequestForCompanySourcesWithoutInventoryTypes.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
		
		QueryResult = RequestForCompanySourcesWithoutInventoryTypes.Execute();
		SelectionDetailRecords = QueryResult.Select();
		If SelectionDetailRecords.Next() Then
			RefillInventoryOwnerAttributes = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure GenerateReplacementTaxInvoices() Export
	
	TableOfModifiedDocuments_ = ModifiedDocuments.UnloadColumns("Document, Organization, Date, EmployeeResponsible");
	For Each Page1 In ModifiedDocuments Do
		If Page1.TaxInvoiceIsIssued
			And Page1.CCDNumbersChanged 
			And ReplacementTaxInvoices.Find(Page1.Document, "Basis") = Undefined Then // and no corrective invoice has been entered before
			FillPropertyValues(TableOfModifiedDocuments_.Add(), Page1);
		EndIf;
	EndDo;
	
	If Not TableOfModifiedDocuments_.Count() Then
		Raise NStr("vi = 'Đã tạo tất cả hóa đơn GTGT cần thiết';
					|ru = 'Все необходимые счета-фактуры уже сформированы';
					|en = 'All necessary tax invoices have already been generated'; fa = 'All necessary tax invoices have already been generated';
					|it = 'Tutte le fatture necessarie sono già state generate';
					|pl = 'Wszystkie niezbędne faktury VAT zostały już utworzone';
					|tr = 'Gerekli tüm vergi faturaları artık oluşturuldu'");
	EndIf;
	
	ArrayOfInvoices_ = VATAccountingERP.GenerateCorrectiveInvoicesForChangedDocuments(TableOfModifiedDocuments_);
	HadErrors = False;
	i = 0;
	For Each Page1 In TableOfModifiedDocuments_ Do
		TaxInvoice = ArrayOfInvoices_[i];
		If TaxInvoice.IsEmpty() Then
			HadErrors = True;
		Else
			CorrectiveInvoicesLine = ReplacementTaxInvoices.Find(Page1.Document, "Basis");
			If CorrectiveInvoicesLine = Undefined Then
				CorrectiveInvoicesLine = ReplacementTaxInvoices.Add();
				CorrectiveInvoicesLine.Basis = Page1.Document;
			EndIf;
			CorrectiveInvoicesLine.Document = TaxInvoice;
		EndIf;
		i = i + 1;
	EndDo;
	
	If HadErrors Then
		MessageText = NStr(
		"vi = 'Không thể tạo hóa đơn GTGT điều chỉnh cho tất cả các chứng từ đã thay đổi. Chi tiết trong nhật ký.';
		|ru = 'Не удалось сформировать исправительные счета-фактуры по всем измененным документов. Подробности в журнале регистрации.';
		|en = 'Cannot generate corrective tax invoices for all changed documents. See the event log for details.'; fa = 'Cannot generate corrective tax invoices for all changed documents. See the event log for details.';
		|it = 'Impossibile generare le fatture di rettifica per tutti i documenti modificati. Dettagli nel registro.';
		|pl = 'Nie udało się sformować korygujące faktury VAT dla wszystkich zmienionych dokumentów. Szczegóły w dzienniku rejestracji.';
		|tr = 'Değiştirilen tüm belgeler için düzeltici vergi faturaları oluşturulamadı. Ayrıntılar kayıt defterinde.'");
		Raise MessageText;
	EndIf;
	
EndProcedure

Procedure ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement(AddressOfAdditionalParameters, WithDetailByPosition) Export
	
	RegistrationControlResult.Clear();
	
	ControlReport = Reports.ControlOfInventoryTransferDocumentRegistration.Create();
	ControlReport.SettingsComposer.LoadSettings(
		ControlReport.DataCompositionSchema.SettingVariants.WizardOfCorrectingCompanyStockBalanceMode.Settings);
	SchemeOfDesignControlResult = ControlReport.DataCompositionSchema;
	
	WarehouseGrouping = ControlReport.SettingsComposer.Settings.Structure[0];
	GroupingTypeOfOperation = WarehouseGrouping.Structure[1];
	GroupingRecommendation = GroupingTypeOfOperation.Structure[0];
	GroupingOrder_ = GroupingRecommendation.Structure[0];
	GroupingDetailsByItem = GroupingOrder_.Structure[0];
	GroupingDetailsByItem.Use = WithDetailByPosition;
	
	FillInSelectionsForGeneratingControlReport();
	
	If TMCommonUse.PlatformVersionNotLowerThanSpecified("8.3.18.1208") Then
		If FiltersToGenerateControlReport.Count() > 0 Then
			AddressOfSelectionTable = PutToTempStorage(FiltersToGenerateControlReport.Unload());
			
			DataCompositionClientServer.SetParameter(ControlReport.SettingsComposer,
															"AddressOfSelectionTable",
															AddressOfSelectionTable);
		EndIf;
	Else
		AddDocumentProcessingControlSelections(ControlReport.SettingsComposer);
	EndIf;
	
	DataCompositionClientServer.SetParameter(ControlReport.SettingsComposer,
													"WizardOfCorrectingCompanyStockBalanceMode",
													True);
	
	LayoutTemplateParameter = ControlReport.SettingsComposer.Settings.OutputParameters.Items.Find("AppearanceTemplate");
	LayoutTemplateParameter.Value = "ReportingBeige";
	LayoutTemplateParameter.Use = True;
	
	DecryptionDataOfRegistrationControlResult = Undefined;
	
	ControlReport.ComposeResult(RegistrationControlResult, DecryptionDataOfRegistrationControlResult);
	
	AddlParameters = New Structure("Schema, DetailsData",
									SchemeOfDesignControlResult, DecryptionDataOfRegistrationControlResult);
	
	PutToTempStorage(AddlParameters, AddressOfAdditionalParameters);
	
EndProcedure

Procedure Initialize() Export
	
	MetadataDataProcessors = Metadata();
	For Each Field In MetadataDataProcessors.Attributes Do
		ThisObject[Field.Name] = Undefined;
	EndDo;
	For Each TS In MetadataDataProcessors.TabularSections Do
		ThisObject[TS.Name].Clear();
	EndDo;
	
EndProcedure

Function StructureOfData() Export
	
	ObjectAsStructure = New Structure;
	
	MetadataDataProcessors = Metadata();
	For Each Field In MetadataDataProcessors.Attributes Do
		ObjectAsStructure.Insert(Field.Name, ThisObject[Field.Name]);
	EndDo;
	For Each TS In MetadataDataProcessors.TabularSections Do
		ObjectAsStructure.Insert(TS.Name, ThisObject[TS.Name].Unload());
	EndDo;
	
	Return ObjectAsStructure;
	
EndFunction

Function NamesOfLongRunningOperations() Export
	
	Array = New Array;
	Array.Add("FillInMonthOfCorrection");
	Array.Add("CreateNewReserves");
	Array.Add("CreateNewReservesForNewSettings");
	Array.Add("GenerateCorrectionsToExpandedBalance");
	Array.Add("RefillInventoryKinds");
	Array.Add("FillInNewTransferSettings");
	Array.Add("GenerateReplacementTaxInvoices");
	Array.Add("ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement");
	Return Array;
	
EndFunction

#EndRegion

#Region Private

Function FollowingAnalysisOfUnfoldedBalance()
	
	If SidedBalanceCorrectionIsRequired Then
		SidedBalanceDimension   = Undefined;
		SidedBalanceCompany = Undefined;
		
		TempTablesManager = New TempTablesManager;
		DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
		RequestForOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance(TempTablesManager, True);
		RequestOrganizationSources = RequestOrganizationSources(TempTablesManager, True, False, True, True);
		
		ResultOfOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance.Execute();
		SelectingOrganizationWithNegativeBalance = ResultOfOrganizationWithNegativeBalance.Select();
		While SelectingOrganizationWithNegativeBalance.Next() Do
			RequestOrganizationSources.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
			RequestOrganizationSources.SetParameter("InventoryType", SelectingOrganizationWithNegativeBalance.InventoryType);
			
			QueryResult = RequestOrganizationSources.Execute();
			SelectionDetailRecords = QueryResult.Select();
			If SelectionDetailRecords.Next() Then
				SidedBalanceDimension   = SelectionDetailRecords.ItemsLocationAttributes;
				SidedBalanceCompany = SelectingOrganizationWithNegativeBalance.Organization;
				
				Return True;
			EndIf;
		EndDo;
		
	ElsIf RefillInventoryOwnerAttributes Then
		SidedBalanceDimension   = Undefined;
		SidedBalanceCompany = Undefined;
		
		TempTablesManager = New TempTablesManager;
		DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
		RequestForOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance(TempTablesManager, True);
		RequestForCompanySourcesWithoutInventoryTypes = RequestForCompanySourcesWithoutInventoryTypes(TempTablesManager, True, False, True, True);

		ResultOfOrganizationWithNegativeBalance = RequestForOrganizationWithNegativeBalance.Execute();
		SelectingOrganizationWithNegativeBalance = ResultOfOrganizationWithNegativeBalance.Select();
		While SelectingOrganizationWithNegativeBalance.Next() Do
			RequestForCompanySourcesWithoutInventoryTypes.SetParameter("Organization", SelectingOrganizationWithNegativeBalance.Organization);
			
			QueryResult = RequestForCompanySourcesWithoutInventoryTypes.Execute();
			SelectionDetailRecords = QueryResult.Select();
			If SelectionDetailRecords.Next() Then
				SidedBalanceDimension   = SelectionDetailRecords.ItemsLocationAttributes;
				SidedBalanceCompany = SelectingOrganizationWithNegativeBalance.Organization;
				
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

Procedure ReFillStockTypesIteration()
	
	For Each Page1 In DocumentsToRefill Do 
		
		UpdateDataOnNegativeBalancesAndBalances();
		ReportProgressOfReplenishmentOfStockTypes();
		
		TempTablesManager = New TempTablesManager;
		DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
		Query = QueryNegativeBalanceAnalysisOfUnfoldedBalance(TempTablesManager);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Break;
		EndIf;
		
		BeginTransaction();
		Try
			
			RecordSet = AccumulationRegisters.CompanyGoods.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Page1.Document);
			RecordSet.Read();
			
			RegisteredRecordsBeforeReFilling = RecordSet.Unload(
				, 
				"Period, RecordType, ItemsLocationAttributes, Organization, InventoryOwnerAttribute, CCDNumber, Count");
			
			DocumentObject = Page1.Document.GetObject();
			If TypeOf(DocumentObject) = Type("DocumentObject.CustomerInvoiceIntercompany") Then
				DocumentObject.SpecifyCCDNumbers = False;
			EndIf;
			DataVersion = DocumentObject.DataVersion;
			DocumentObject.AdditionalProperties.Insert("RefillInventoryKinds", True);
			DocumentObject.AdditionalProperties.Insert(
				"BeginningOfPeriodForCorrectingBalances", 
				BegOfMonth(MonthOfCorrection));
			DocumentObject.AdditionalProperties.Insert(
				"EndOfPeriodForCorrectingBalances", 
				EndOfMonth(MonthOfCorrection));
			SetPrivilegedMode(True);
			DocumentObject.Write(DocumentWriteMode.Posting);
			SetPrivilegedMode(False);
			If RegisteredRecordsHaveChanged(RegisteredRecordsBeforeReFilling, DocumentObject.Ref, False) Then
				NewRow = ModifiedDocuments.Find(DocumentObject.Ref, "Document");
				If NewRow = Undefined Then
					NewRow = ModifiedDocuments.Add();
				EndIf;
				NewRow.Document = DocumentObject.Ref;
				TaxInvoiceIsIssued = VATAccountingERP.InvoicesIssuedOnLegalGrounds(DocumentObject.Ref).Count();
				If TaxInvoiceIsIssued Then
					NewRow.TaxInvoiceIsIssued = True;
					NewRow.CCDNumbersChanged = RegisteredRecordsHaveChanged(RegisteredRecordsBeforeReFilling, DocumentObject.Ref, True);
					NewRow.EmployeeResponsible = DocumentObject.Manager;
					NewRow.Organization = DocumentObject.Organization;
					NewRow.Date = DocumentObject.Date;
				EndIf;
			EndIf;
			CommitTransaction();
			
		Except
			RollbackTransaction();
			ErrorText = NStr("vi = 'Đã xảy ra lỗi trong khi bổ sung các loại hàng tồn kho trong kỳ %CurrentMonth%: %ErrorReason%';
							|ru = 'Возникла ошибка при перезаполнении видов запасов за период %CurrentMonth%: %ErrorReason%';
							|en = 'An error occurred while refilling inventory owner attributes for the %CurrentMonth% period. Reason:%ErrorReason%'; fa = 'An error occurred while refilling inventory owner attributes for the %CurrentMonth% period. Reason:%ErrorReason%';
							|it = 'Si è verificato un errore durante la ricompilazione dei tipi delle scorte per il periodo %CurrentMonth%: %ErrorReason%';
							|pl = 'Wystąpił błąd podczas ponownego wypełniania rodzajów zapasów za okres %CurrentMonth%: %ErrorReason%';
							|tr = '%CurrentMonth% dönemi için stok türleri aşırı doldurulurken hata oluştu: %ErrorReason%'");
			ErrorText = StrReplace(ErrorText, "%ErrorReason%", DetailErrorDescription(ErrorInfo()));
			ErrorText = StrReplace(ErrorText, "%CurrentMonth%", Format(MonthOfCorrection, "DLF=DD"));
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure ReportProgressOfReplenishmentOfStockTypes()
	
	If Not ItemQuantitySidedBalanceBeforeCorrection Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Thực hiện điền lại dạng hàng tồn kho';
						|ru = 'Выполняется перезаполнение видов запасов';
						|en = 'Refilling inventory owner attributes'; fa = 'Refilling inventory owner attributes';
						|it = 'Ricompilazione dei tipi delle scorte è in corso';
						|pl = 'Odbywa się ponowne wypełnienie rodzajów zapasów';
						|tr = 'Stok türlerinin yeniden doldurulması gerçekleştiriliyor'");
	If Percent = Undefined Then
		Percent = 0;
		TimeConsumingOperations.ReportProgress(0, MessageText);
	EndIf;
	NewPercentage = 
		100 
		- (NumberOfPositionsNegativeBalance + ItemQuantitySidedBalance) 
		/ (NumberOfPositionsNegativeBalanceBefore + ItemQuantitySidedBalanceBeforeCorrection) 
		* 100;
	If NewPercentage - Percent > 1 Then // triggered no more than 100 times
		Percent = NewPercentage;
		TimeConsumingOperations.ReportProgress(Round(Percent), MessageText);
	EndIf;
	
EndProcedure

Function RegisteredRecordsHaveChanged(RegisteredRecordsBeforeReFilling, DocumentRef, OnlyByCCDNumbers)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CompanyGoods.Period AS Period,
	|	CompanyGoods.RecordType AS RecordType,
	|	CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoods.Organization AS Organization,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoods.CCDNumber AS CCDNumber,
	|	CompanyGoods.Count AS Count
	|INTO RegisteredRecordsBeforeReFilling
	|FROM
	|	&RegisteredRecordsBeforeReFilling AS CompanyGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	NestedQuery.Period AS Period,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	&QueryTextInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	SUM(NestedQuery.Count) AS Count
	|FROM
	|	(SELECT
	|		CompanyGoods.Period AS Period,
	|		CompanyGoods.RecordType AS RecordType,
	|		CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CompanyGoods.Organization AS Organization,
	|		CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanyGoods.CCDNumber AS CCDNumber,
	|		CompanyGoods.Count AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|	WHERE
	|		CompanyGoods.Recorder = &Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisteredRecordsBeforeReFilling.Period,
	|		RegisteredRecordsBeforeReFilling.RecordType,
	|		RegisteredRecordsBeforeReFilling.ItemsLocationAttributes,
	|		RegisteredRecordsBeforeReFilling.Organization,
	|		RegisteredRecordsBeforeReFilling.InventoryOwnerAttribute,
	|		RegisteredRecordsBeforeReFilling.CCDNumber,
	|		-RegisteredRecordsBeforeReFilling.Count
	|	FROM
	|		RegisteredRecordsBeforeReFilling AS RegisteredRecordsBeforeReFilling) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Period,
	|	NestedQuery.Organization,
	|	NestedQuery.RecordType,
	|	&QueryTextInventoryOwnerAttribute,
	|	NestedQuery.CCDNumber
	|
	|HAVING
	|	SUM(NestedQuery.Count) <> 0";
	
	Query.SetParameter("RegisteredRecordsBeforeReFilling", RegisteredRecordsBeforeReFilling);
	Query.SetParameter("Recorder", DocumentRef);
	
	If OnlyByCCDNumbers Then
		// When the types of stocks are replenished, the types of stocks and GTD numbers may change. To analyze changes only by GTD numbers
		// , we exclude the types of stocks from the grouping fields.
		Query.Text = StrReplace(Query.Text, "&QueryTextInventoryOwnerAttribute", "UNDEFINED");
	Else
		Query.Text = StrReplace(Query.Text, "&QueryTextInventoryOwnerAttribute", "InventoryOwnerAttribute");
	EndIf;
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

Procedure FillInListOfDocumentsToBeRefilled()
	
	TempTablesManager = New TempTablesManager;
	DataProcessors.WizardOfCorrectingCompanyStockBalance.GenerateTTControlledInventoryTypes(TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		Organization = &Organization
		|			AND ItemsLocationAttributes = &ItemsLocationAttributes
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTControlledInventoryTypes.Ref
		|				FROM
		|					TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND CompanyGoodsOnWay.Organization = &Organization
		|	AND CompanyGoodsOnWay.ItemsLocationAttributes = &ItemsLocationAttributes
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes AS TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&CorrectionBoundary,
		|		Organization = &Organization
		|			AND ItemsLocationAttributes = &ItemsLocationAttributes
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTControlledInventoryTypes.Ref
		|				FROM
		|					TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 						AS CCDNumber
		|INTO SelectionOfRegistrars
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SelectionOfRegistrars.Organization 					AS Organization,
		|	SelectionOfRegistrars.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	SelectionOfRegistrars.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	SelectionOfRegistrars.CCDNumber 					AS CCDNumber
		|FROM
		|	SelectionOfRegistrars AS SelectionOfRegistrars
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CompanyGoods.Recorder AS Document
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|WHERE
		|	(CompanyGoods.Organization, CompanyGoods.ItemsLocationAttributes, CompanyGoods.InventoryOwnerAttribute, CompanyGoods.CCDNumber) IN (
		|		SELECT
		|			SelectionOfRegistrars.Organization AS Organization,
		|			SelectionOfRegistrars.ItemsLocationAttributes AS ItemsLocationAttributes,
		|			SelectionOfRegistrars.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|			SelectionOfRegistrars.CCDNumber AS CCDNumber
		|		FROM
		|			SelectionOfRegistrars AS SelectionOfRegistrars)
		|	AND CompanyGoods.Period BETWEEN &StartDate AND &EndDate
		|	AND (CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND CompanyGoods.Count > 0
		|		OR CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND CompanyGoods.Count < 0)
		|	AND NOT CompanyGoods.Recorder REFS Document.RegisterAdjustment
		|	AND NOT CompanyGoods.Recorder REFS Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SelectionOfRegistrars";
	
	Query.SetParameter("StartDate",                 BegOfMonth(MonthOfCorrection));
	Query.SetParameter("EndDate",                  EndOfMonth(MonthOfCorrection));
	Query.SetParameter("Organization",                SidedBalanceCompany);
	Query.SetParameter("ItemsLocationAttributes", SidedBalanceDimension);
	Query.SetParameter("CorrectionBoundary",         New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",          EndOfMonth(MonthOfCorrection));
	
	QueryResult = Query.ExecuteBatch();
	UBound         = QueryResult.UBound();
	
	If QueryResult[UBound - 2].IsEmpty() <> QueryResult[UBound - 1].IsEmpty() Then
		ExceptionText = 
			NStr("vi = 'Theo chỉ số kế toán mặt hàng %ItemsLocationAttributes% chưa tìm thấy chứng từ để điền lại dạng vật tư';
				|ru = 'По аналитике учета номенклатуры %ItemsLocationAttributes% не найдены документы для перезаполнения видов запасов';
				|en = 'No documents are found for refilling inventory owner attributes under the %ItemsLocationAttributes% inventory location attributes'; fa = 'No documents are found for refilling inventory owner attributes under the %ItemsLocationAttributes% inventory location attributes';
				|it = 'Non sono stati trovati documenti per la ricompilazione dei tipi delle scorte secondo l''analisi di contabilità dell''articolo %ItemsLocationAttributes%';
				|pl = 'Według analiz ewidencji nomenklatury %ItemsLocationAttributes% nie znaleziono dokumentów dla ponownego wypełnienia rodzajów zapasów';
				|tr = 'Stok türlerini yeniden doldurmak için %ItemsLocationAttributes% muhasebe boyutu öğesi için belge bulunamadı'",
			Metadata.DefaultLanguage.LanguageCode);
		ExceptionText = StrReplace(ExceptionText, "%ItemsLocationAttributes%", Format(SidedBalanceDimension));
		
		WriteLogEvent(
			EventName(),
			EventLogLevel.Error,
			Metadata.DataProcessors.WizardOfCorrectingCompanyStockBalance,
			,
			ExceptionText);
		Raise ExceptionText;
		
	Else
		DocumentsToRefill.Load(QueryResult[UBound - 1].Unload());
	EndIf;
	
EndProcedure

Procedure UncheckInventoryTypesFlagSpecifiedManually()
	
	For Each Page1 In DocumentsToRefill Do
		DocumentObject = Page1.Document.GetObject();
		If Common.HasObjectAttribute("InventoryOwnerAttributesAreSpecifiedManually", DocumentObject.Metadata())
			And DocumentObject.InventoryOwnerAttributesAreSpecifiedManually Then
			DocumentObject.InventoryOwnerAttributesAreSpecifiedManually = False;
			DocumentObject.DataExchange.Load = True;
			DocumentObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

Function EventName()
	Return NStr("vi = 'Lỗi khi làm việc với Trợ giúp sửa số dư hàng hóa trong doanh nghiệp';
				|ru = 'Ошибка при работе помощника исправления остатков товаров организаций';
				|en = 'An error occurred in the wizard of correcting company stock balance'; fa = 'An error occurred in the wizard of correcting company stock balance';
				|it = 'Errore durante l''utilizzo dell''assistente per la rettifica delle rimanenze merci delle società';
				|pl = 'Błąd podczas pracy asystenta korekty stanów magazynowych firmy';
				|tr = 'İş yerlerinin ürün bakiyesini düzeltmek için sihirbaz çalışması sırasında hata'",  
		CommonClientServer.DefaultLanguageCode());
EndFunction

Procedure AddDocumentProcessingControlSelections(SettingsComposer)
	
	If FiltersToGenerateControlReport.Count() = 0 Then
		Return;
	EndIf;
	
	OrGroup = DataCompositionClientServer.AddSelectionGroup(
					SettingsComposer.Settings.Filter.Items,
					DataCompositionFilterItemsGroupType.OrGroup); // DataCompositionFilterItemGroup
	
	For Each Page1 In FiltersToGenerateControlReport Do
		AndGroup = DataCompositionClientServer.AddSelectionGroup(
					OrGroup.Items,
					DataCompositionFilterItemsGroupType.AndGroup);
		
		DataCompositionClientServer.AddFilter(
			AndGroup,
			"Products",
			Page1.Products,
			DataCompositionComparisonType.Equal);
		DataCompositionClientServer.AddFilter(
			AndGroup,
			"Characteristic",
			Page1.Characteristic,
			DataCompositionComparisonType.Equal);
		DataCompositionClientServer.AddFilter(
			AndGroup,
			"Series",
			Page1.Series,
			DataCompositionComparisonType.Equal);
		DataCompositionClientServer.AddFilter(
			AndGroup,
			"Warehouse",
			Page1.Warehouse,
			DataCompositionComparisonType.Equal);
		DataCompositionClientServer.AddFilter(
			AndGroup,
			"Purpose",
			Page1.Purpose,
			DataCompositionComparisonType.Equal);
	EndDo;
	
EndProcedure

Procedure FillInSelectionsForGeneratingControlReport()
	
	Query = RequestingSelectionsOfProblematicBalances();
	Query.Text = Query.Text + Common.QueryBatchSeparator() + 
	"SELECT DISTINCT
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	InventoryLocationAttributeKeys.Series AS Series,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	InventoryLocationAttributeKeys.Purpose AS Purpose
	|FROM
	|	SelectingProblematicResidues AS SelectingProblematicResidues
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON SelectingProblematicResidues.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref";
	
	QueryResult = Query.Execute();
	
	FiltersToGenerateControlReport.Load(QueryResult.Unload());
	
EndProcedure

Procedure ClearReserves(FilterType)
	
	Query = RequestingSelectionsOfProblematicBalances();
	Query.Text = Query.Text + Common.QueryBatchSeparator() +
	"SELECT
	|	CompanySafeStock.Recorder AS Recorder,
	|	CompanySafeStock.LineNumber AS LineNumber
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Period BETWEEN BEGINOFPERIOD(&MonthOfCorrection, MONTH) AND ENDOFPERIOD(&MonthOfCorrection, MONTH)
	|	AND (CompanySafeStock.ItemsLocationAttributes, CompanySafeStock.Organization) IN
	|			(SELECT
	|				FilterNegative_Balance.ItemsLocationAttributes,
	|				FilterNegative_Balance.Organization
	|			FROM
	|				FilterNegative_Balance)
	|	AND CompanySafeStock.InventoryOwnerAttribute IN
	|			(SELECT
	|				TTControlledInventoryTypes.Ref
	|			FROM
	|				TTControlledInventoryTypes)
	|	AND &FilterType = ""Negative_Balance""
	|
	|UNION
	|
	|SELECT
	|	CompanySafeStock.Recorder,
	|	CompanySafeStock.LineNumber
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Period BETWEEN BEGINOFPERIOD(&MonthOfCorrection, MONTH) AND ENDOFPERIOD(&MonthOfCorrection, MONTH)
	|	AND (CompanySafeStock.ItemsLocationAttributes, CompanySafeStock.CorCompany) IN
	|			(SELECT
	|				FilterNegative_Balance.ItemsLocationAttributes,
	|				FilterNegative_Balance.Organization
	|			FROM
	|				FilterNegative_Balance)
	|	AND CompanySafeStock.CorInventoryOwnerAttribute IN
	|			(SELECT
	|				TTControlledInventoryTypes.Ref
	|			FROM
	|				TTControlledInventoryTypes)
	|	AND &FilterType = ""Negative_Balance""
	|
	|UNION
	|
	|SELECT
	|	CompanySafeStock.Recorder,
	|	CompanySafeStock.LineNumber
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Period BETWEEN BEGINOFPERIOD(&MonthOfCorrection, MONTH) AND ENDOFPERIOD(&MonthOfCorrection, MONTH)
	|	AND CompanySafeStock.ItemsLocationAttributes = &SidedBalanceDimension
	|	AND CompanySafeStock.Organization = &SidedBalanceCompany
	|	AND CompanySafeStock.InventoryOwnerAttribute IN
	|			(SELECT
	|				TTControlledInventoryTypes.Ref
	|			FROM
	|				TTControlledInventoryTypes)
	|	AND &FilterType = ""ByAnalytics""
	|
	|UNION
	|
	|SELECT
	|	CompanySafeStock.Recorder,
	|	CompanySafeStock.LineNumber
	|FROM
	|	AccumulationRegister.CompanySafeStock AS CompanySafeStock
	|WHERE
	|	CompanySafeStock.Period BETWEEN BEGINOFPERIOD(&MonthOfCorrection, MONTH) AND ENDOFPERIOD(&MonthOfCorrection, MONTH)
	|	AND CompanySafeStock.ItemsLocationAttributes = &SidedBalanceDimension
	|	AND CompanySafeStock.CorCompany = &SidedBalanceCompany
	|	AND CompanySafeStock.CorInventoryOwnerAttribute IN
	|			(SELECT
	|				TTControlledInventoryTypes.Ref
	|			FROM
	|				TTControlledInventoryTypes)
	|	AND &FilterType = ""ByAnalytics""
	|
	|ORDER BY
	|	Recorder,
	|	LineNumber DESC";
	
	Query.SetParameter("MonthOfCorrection", MonthOfCorrection);
	Query.SetParameter("FilterType", FilterType);
	Query.SetParameter("SidedBalanceDimension", SidedBalanceDimension);
	Query.SetParameter("SidedBalanceCompany", SidedBalanceCompany);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	Recorder = Undefined;
	Set = Undefined;
	
	SetPrivilegedMode(True);
	While SelectionDetailRecords.Next() Do
		If Recorder <> SelectionDetailRecords.Recorder Then
			If Set <> Undefined Then
				Set.Write();
			EndIf;
			Recorder = SelectionDetailRecords.Recorder;
			Set = AccumulationRegisters.CompanySafeStock.CreateRecordSet();
			Set.Filter.Recorder.Set(Recorder);
			Set.Read();
			Set.DataExchange.Load = True;
		EndIf;
		Set.Delete(SelectionDetailRecords.LineNumber - 1);
	EndDo;
	
	If Set <> Undefined Then
		Set.Write();
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

Function RequestOrganizationSources(TempTablesManager, GroupLeftoversByCCDNumbers, OnlyByMatchingCCDNumbers, 
			OnlyFirstSource, IncludingYourOwn)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager; 
	Query.Text = 
		TextOfBalanceSelectionRequest() + 
		Common.QueryBatchSeparator() +
		
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(&CorrectionBoundary, ) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(&CorrectionBoundary, ) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	&TextNameAndNumberOfCCD 							AS CCDNumber
		|INTO FilterPositions_2
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|WHERE
		|	(BalancesAtEndOfPeriod.Organization, BalancesAtEndOfPeriod.InventoryOwnerAttribute) IN
		|			(SELECT
		|				StockSelection.Organization,
		|				StockSelection.InventoryOwnerAttribute
		|			FROM
		|				StockSelection)
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	&TextNameOfGroupingOfCCDNumbers
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&OnlyFirstSource,
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	&TextNameAndNumberOfCCD 							AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 		AS CountBalance
		|INTO GroupedSourceBalances
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|WHERE
		|	(BalancesAtEndOfPeriod.Organization, BalancesAtEndOfPeriod.InventoryOwnerAttribute) IN
		|			(SELECT
		|				SourceStockSelection.Organization,
		|				SourceStockSelection.InventoryOwnerAttribute
		|			FROM
		|				SourceStockSelection)
		|	AND (BalancesAtEndOfPeriod.ItemsLocationAttributes, &TextNameAndNumberOfCCD) IN
		|			(SELECT
		|				FilterPositions_2.ItemsLocationAttributes,
		|				&TextSelectionValueCCDNumber
		|			FROM
		|				FilterPositions_2)
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	&TextNameOfGroupingOfCCDNumbers
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GroupedSourceBalances.Organization 				AS Organization,
		|	GroupedSourceBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryLocationAttributeKeys.Products 				AS Products,
		|	InventoryLocationAttributeKeys.StorageLocation 				AS Warehouse,
		|	TypesOfSourceStocks.InventoryType 							AS InventoryType,
		|	GroupedSourceBalances.CCDNumber 					AS CCDNumber
		|FROM
		|	GroupedSourceBalances AS GroupedSourceBalances
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON GroupedSourceBalances.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		INNER JOIN Catalog.InventoryKinds AS TypesOfSourceStocks
		|		ON GroupedSourceBalances.InventoryOwnerAttribute = TypesOfSourceStocks.Ref
		|		INNER JOIN FilterPositions_2 AS FilterPositions_2
		|		ON GroupedSourceBalances.ItemsLocationAttributes = FilterPositions_2.ItemsLocationAttributes
		|			AND GroupedSourceBalances.CCDNumber = FilterPositions_2.CCDNumber
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON FilterPositions_2.InventoryOwnerAttribute = InventoryKinds.Ref
		|			AND CASE
		|				WHEN InventoryKinds.InventoryType IN (&InventoryTypesExternalOwner)
		|					THEN InventoryKinds.GoodsOwner
		|				ELSE UNDEFINED
		|			END = CASE
		|				WHEN TypesOfSourceStocks.InventoryType IN (&InventoryTypesExternalOwner)
		|					THEN TypesOfSourceStocks.GoodsOwner
		|				ELSE UNDEFINED
		|			END
		|
		|ORDER BY
		|	GroupedSourceBalances.Organization,
		|	TypesOfSourceStocks.InventoryType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SourceStockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP StockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP FilterPositions_2
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GroupedSourceBalances";
	
	Query.Text = StrReplace(
		Query.Text, "&TextNameAndNumberOfCCD", ?(OnlyByMatchingCCDNumbers, "BalancesAtEndOfPeriod.CCDNumber", "UNDEFINED"));
	Query.Text = StrReplace(
		Query.Text, "&TextSelectionValueCCDNumber", ?(OnlyByMatchingCCDNumbers, "FilterPositions_2.CCDNumber", "UNDEFINED"));
	Query.Text = StrReplace(
		Query.Text, "&TextNameOfGroupingOfCCDNumbers", ?(GroupLeftoversByCCDNumbers, "BalancesAtEndOfPeriod.CCDNumber", "UNDEFINED"));

	If OnlyFirstSource Then
		Query.Text = StrReplace(Query.Text, "&OnlyFirstSource,", "TOP 1");
	Else	
		Query.Text = StrReplace(Query.Text, "&OnlyFirstSource,", "");
	EndIf;
		
	Query.SetParameter("IncludingYourOwn", 	    IncludingYourOwn);
	Query.SetParameter("InventoryTypesExternalOwner", Enums.InventoryTypes.InventoryTypesExternalOwner());
	Query.SetParameter("CorrectionBoundary", 	    New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",          EndOfMonth(MonthOfCorrection));
	
	Return Query;

EndFunction

Function RequestForCompanySourcesWithoutInventoryTypes(TempTablesManager, GroupLeftoversByCCDNumbers, OnlyByMatchingCCDNumbers, 
			OnlyFirstSource, IncludingYourOwn)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager; 
	Query.Text = 
		QueryTextForSelectingBalancesWithoutInventoryTypes() + 
		Common.QueryBatchSeparator() +
		
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(&CorrectionBoundary,) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(&CorrectionBoundary,) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	&TextNameAndNumberOfCCD 							AS CCDNumber
		|INTO FilterPositions_2
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|WHERE
		|	(BalancesAtEndOfPeriod.Organization, BalancesAtEndOfPeriod.InventoryOwnerAttribute) IN
		|			(SELECT
		|				StockSelection.Organization,
		|				StockSelection.InventoryOwnerAttribute
		|			FROM
		|				StockSelection)
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	&TextNameOfGroupingOfCCDNumbers
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&OnlyFirstSource,
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	&TextNameAndNumberOfCCD 							AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 		AS CountBalance
		|INTO GroupedSourceBalances
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|WHERE
		|	(BalancesAtEndOfPeriod.Organization, BalancesAtEndOfPeriod.InventoryOwnerAttribute) IN
		|			(SELECT
		|				SourceStockSelection.Organization,
		|				SourceStockSelection.InventoryOwnerAttribute
		|			FROM
		|				SourceStockSelection)
		|	AND (BalancesAtEndOfPeriod.ItemsLocationAttributes, &TextNameAndNumberOfCCD) IN (
		|		SELECT
		|			FilterPositions_2.ItemsLocationAttributes,
		|			&TextSelectionValueCCDNumber
		|		FROM
		|			FilterPositions_2)
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	&TextNameOfGroupingOfCCDNumbers
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GroupedSourceBalances.Organization 				AS Organization,
		|	GroupedSourceBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryLocationAttributeKeys.Products 				AS Products,
		|	InventoryLocationAttributeKeys.StorageLocation 				AS Warehouse,
		|	TypesOfSourceStocks.InventoryType 							AS InventoryType,
		|	GroupedSourceBalances.CCDNumber 					AS CCDNumber
		|FROM
		|	GroupedSourceBalances AS GroupedSourceBalances
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON GroupedSourceBalances.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		INNER JOIN Catalog.InventoryKinds AS TypesOfSourceStocks
		|		ON GroupedSourceBalances.InventoryOwnerAttribute = TypesOfSourceStocks.Ref
		|		INNER JOIN FilterPositions_2 AS FilterPositions_2
		|		ON GroupedSourceBalances.ItemsLocationAttributes = FilterPositions_2.ItemsLocationAttributes
		|			AND GroupedSourceBalances.CCDNumber = FilterPositions_2.CCDNumber
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON FilterPositions_2.InventoryOwnerAttribute = InventoryKinds.Ref
		|
		|ORDER BY
		|	GroupedSourceBalances.Organization,
		|	TypesOfSourceStocks.InventoryType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SourceStockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP StockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP FilterPositions_2
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GroupedSourceBalances";
	
	Query.Text = StrReplace(
		Query.Text, "&TextNameAndNumberOfCCD", ?(OnlyByMatchingCCDNumbers, "BalancesAtEndOfPeriod.CCDNumber", "UNDEFINED"));
	Query.Text = StrReplace(
		Query.Text, "&TextSelectionValueCCDNumber", ?(OnlyByMatchingCCDNumbers, "FilterPositions_2.CCDNumber", "UNDEFINED"));
	Query.Text = StrReplace(
		Query.Text, "&TextNameOfGroupingOfCCDNumbers", ?(GroupLeftoversByCCDNumbers, "BalancesAtEndOfPeriod.CCDNumber", "UNDEFINED"));

	If OnlyFirstSource Then
		Query.Text = StrReplace(Query.Text, "&OnlyFirstSource,", "TOP 1");
	Else	
		Query.Text = StrReplace(Query.Text, "&OnlyFirstSource,", "");
	EndIf;
		
	Query.SetParameter("IncludingYourOwn", 	    IncludingYourOwn);
	Query.SetParameter("InventoryTypesExternalOwner", Enums.InventoryTypes.InventoryTypesExternalOwner());
	Query.SetParameter("CorrectionBoundary", 	    New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",          EndOfMonth(MonthOfCorrection));
	
	Return Query;

EndFunction

Function TextOfBalanceSelectionRequest()
	
	QueryText = 
		"SELECT
		|	TableOfSourceOrganizations.SourceOrganization AS Organization,
		|	TypesOfSourceStocks.Ref AS InventoryOwnerAttribute
		|INTO SourceStockSelection
		|FROM
		|	TableOfSourceOrganizations AS TableOfSourceOrganizations
		|		INNER JOIN Catalog.InventoryKinds AS TypesOfSourceStocks
		|		ON TableOfSourceOrganizations.SourceInventoryType = TypesOfSourceStocks.InventoryType
		|			AND TableOfSourceOrganizations.SourceOrganization = TypesOfSourceStocks.Organization
		|WHERE
		|	TableOfSourceOrganizations.InventoryType = &InventoryType
		|	AND TableOfSourceOrganizations.Organization = &Organization
		|	AND NOT TypesOfSourceStocks.SubjectToExcise
		|
		|UNION ALL
		|
		|SELECT
		|	&Organization AS Organization,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Organization = &Organization
		|	AND InventoryKinds.InventoryType = &InventoryType
		|	AND &IncludingYourOwn
		|	AND NOT InventoryKinds.SubjectToExcise
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Organization AS Organization,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|INTO StockSelection
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Organization = &Organization
		|	AND InventoryKinds.InventoryType = &InventoryType";

	Return QueryText;

EndFunction

Function QueryTextForSelectingBalancesWithoutInventoryTypes()
	
	QueryText = 
		"SELECT
		|	TableOfSourceOrganizations.SourceOrganization AS Organization,
		|	TypesOfSourceStocks.Ref AS InventoryOwnerAttribute
		|INTO SourceStockSelection
		|FROM
		|	TableOfSourceOrganizations AS TableOfSourceOrganizations
		|		INNER JOIN Catalog.InventoryKinds AS TypesOfSourceStocks
		|		ON TableOfSourceOrganizations.SourceInventoryType = TypesOfSourceStocks.InventoryType
		|			AND TableOfSourceOrganizations.SourceOrganization = TypesOfSourceStocks.Organization
		|WHERE
		|	TableOfSourceOrganizations.Organization = &Organization
		|
		|UNION ALL
		|
		|SELECT
		|	&Organization AS Organization,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Organization = &Organization
		|	AND &IncludingYourOwn
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Organization AS Organization,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|INTO StockSelection
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Organization = &Organization";

	Return QueryText;

EndFunction

Function RequestForOrganizationWithNegativeBalance(TempTablesManager, ThereIsTransferSetting)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes AS TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&CorrectionBoundary,
		|		InventoryOwnerAttribute IN (
		|			SELECT
		|				TTControlledInventoryTypes.Ref
		|			FROM
		|				TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 	AS Organization,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 	AS InventoryOwnerAttribute
		|INTO StocksWithNegativeBalance
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	StocksWithNegativeBalance.Organization 	AS Organization,
		|	InventoryKinds.InventoryType 						AS InventoryType,
		|	CASE
		|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|			THEN VALUE(Enum.GoodsTransferMethods.Sale)
		|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
		|		ELSE UNDEFINED
		|	END AS GoodsTransferMethod
		|INTO OrganizationsWithNegativeBalanceByInventoryType
		|FROM
		|	StocksWithNegativeBalance AS StocksWithNegativeBalance
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON StocksWithNegativeBalance.InventoryOwnerAttribute = InventoryKinds.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrganizationsWithNegativeBalanceByInventoryType.Organization 	AS Organization,
		|	OrganizationsWithNegativeBalanceByInventoryType.InventoryType 		AS InventoryType,
		|	CustomizeCustomerInvoiceIntercompany.CompanyOwner 	AS SourceOrganization,
		|	CustomizeCustomerInvoiceIntercompany.InventoryType 			AS SourceInventoryType
		|INTO TableOfSourceOrganizations
		|FROM
		|	OrganizationsWithNegativeBalanceByInventoryType AS OrganizationsWithNegativeBalanceByInventoryType
		|		INNER JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
		|		ON OrganizationsWithNegativeBalanceByInventoryType.Organization = CustomizeCustomerInvoiceIntercompany.CompanyCustomer
		|			AND OrganizationsWithNegativeBalanceByInventoryType.GoodsTransferMethod = CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod
		|WHERE
		|	&ThereIsTransferSetting
		|
		|UNION ALL
		|
		|SELECT
		|	OrganizationsWithNegativeBalanceByInventoryType.Organization,
		|	OrganizationsWithNegativeBalanceByInventoryType.InventoryType,
		|	Companies.Ref,
		|	InventoryTypes.Ref
		|FROM
		|	OrganizationsWithNegativeBalanceByInventoryType AS OrganizationsWithNegativeBalanceByInventoryType
		|		INNER JOIN Catalog.Companies AS Companies
		|		ON OrganizationsWithNegativeBalanceByInventoryType.Organization <> Companies.Ref
		|		INNER JOIN Enum.InventoryTypes AS InventoryTypes
		|		ON (InventoryTypes.Ref IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods), VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)))
		|		LEFT JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
		|		ON (CustomizeCustomerInvoiceIntercompany.CompanyOwner = Companies.Ref)
		|			AND (CustomizeCustomerInvoiceIntercompany.InventoryType = InventoryTypes.Ref)
		|			AND (CustomizeCustomerInvoiceIntercompany.CompanyCustomer = OrganizationsWithNegativeBalanceByInventoryType.Organization)
		|			AND (CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = OrganizationsWithNegativeBalanceByInventoryType.GoodsTransferMethod)
		|WHERE
		|	NOT &ThereIsTransferSetting
		|	AND CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrganizationsWithNegativeBalanceByInventoryType.Organization AS Organization,
		|	OrganizationsWithNegativeBalanceByInventoryType.InventoryType  AS InventoryType
		|FROM
		|	OrganizationsWithNegativeBalanceByInventoryType AS OrganizationsWithNegativeBalanceByInventoryType
		|
		|ORDER BY
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP StocksWithNegativeBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OrganizationsWithNegativeBalanceByInventoryType";
	
	Query.SetParameter("ThereIsTransferSetting", ThereIsTransferSetting);
	Query.SetParameter("CorrectionBoundary",    New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",     EndOfMonth(MonthOfCorrection));
	
	Return Query;

EndFunction

Function RequestingNumberOfProblemPositions()
	
	Query = RequestingSelectionsOfProblematicBalances();
	
	Query.Text = 
		Query.Text + 
		Common.QueryBatchSeparator() + 
		
		"SELECT
		|	COUNT(SelectingProblematicResidues.ItemsLocationAttributes) AS NumberOfRows
		|FROM
		|	SelectingProblematicResidues AS SelectingProblematicResidues
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(FilterNegative_Balance.ItemsLocationAttributes) AS NumberOfRows
		|FROM
		|	FilterNegative_Balance AS FilterNegative_Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	0 AS NumberOfRows";
	Query.Text = StrReplace(
		Query.Text, 
		"SELECT
		|	0 AS NumberOfRows",
		"SELECT
		|	COUNT(SelectionNegativeBalancesOther.ItemsLocationAttributes) AS NumberOfRows
		|FROM
		|	SelectionNegativeBalancesOther AS SelectionNegativeBalancesOther");
	Return Query;

EndFunction

Function RequestingSelectionsOfProblematicBalances()
	
	Query = DataProcessors.WizardOfCorrectingCompanyStockBalance.RequestDetailedMonthEndBalances(MonthOfCorrection);
	
	Query.Text = 
		Query.Text + 
		Common.QueryBatchSeparator() +
		
		"SELECT DISTINCT
		|	DetailedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DetailedBalance.Organization AS Organization
		|INTO SelectingProblematicResidues
		|FROM
		|	DetailedBalancesAtEndOfMonth AS DetailedBalance
		|
		|GROUP BY
		|	DetailedBalance.ItemsLocationAttributes,
		|	DetailedBalance.Organization,
		|	DetailedBalance.InventoryOwnerAttribute,
		|	DetailedBalance.CCDNumber
		|
		|HAVING
		|	SUM(DetailedBalance.CountBalance) < 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DetailedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	ISNULL(InventoryKinds.SubjectToExcise, FALSE) AS SubjectToExcise,
		|	DetailedBalance.Organization AS Organization
		|INTO FilterNegative_Balance
		|FROM
		|	DetailedBalancesAtEndOfMonth AS DetailedBalance
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON DetailedBalance.InventoryOwnerAttribute = InventoryKinds.Ref
		|
		|GROUP BY
		|	DetailedBalance.ItemsLocationAttributes,
		|	DetailedBalance.Organization,
		|	ISNULL(InventoryKinds.SubjectToExcise, FALSE),
		|	CASE
		|		WHEN InventoryKinds.InventoryType IN (&InventoryTypesExternalOwner)
		|			THEN InventoryKinds.GoodsOwner
		|		ELSE UNDEFINED
		|	END
		|
		|HAVING
		|	SUM(DetailedBalance.CountBalance) < 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	SubjectToExcise,
		|	Organization";
	
	Query.SetParameter("InventoryTypesExternalOwner", Enums.InventoryTypes.InventoryTypesExternalOwner());
	Query.Text = 
		Query.Text + 
		Common.QueryBatchSeparator() +
		
		"SELECT DISTINCT
		|	DetailedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DetailedBalance.Organization AS Organization
		|INTO SelectionNegativeBalancesOther
		|FROM
		|	DetailedBalancesAtEndOfMonth AS DetailedBalance
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON DetailedBalance.InventoryOwnerAttribute = InventoryKinds.Ref
		|WHERE
		|	InventoryKinds.InventoryType IN (&InventoryTypesOther)
		|
		|GROUP BY
		|	DetailedBalance.ItemsLocationAttributes,
		|	DetailedBalance.Organization
		|
		|HAVING
		|	SUM(DetailedBalance.CountBalance) < 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization";
	
	InventoryTypesOther = New Array;
	InventoryTypesOther.Add(Enums.InventoryTypes.SubcontractorProducts);
	InventoryTypesOther.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	Query.SetParameter("InventoryTypesOther", InventoryTypesOther);
	Return Query;

EndFunction

Function RequestSourcesOfExpandedBalanceCoverage(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		TextOfBalanceSelectionRequest() + 
		Common.QueryBatchSeparator() +
		
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance,
		|	CompanyGoodsBalance.QuantityByGBRNBalance 	AS QuantityByGBRNBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		(Organization, InventoryOwnerAttribute) IN (
		|			SELECT
		|				StockSelection.Organization,
		|				StockSelection.InventoryOwnerAttribute
		|			FROM
		|				StockSelection)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance,
		|	0												 	AS QuantityByGBRNBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND (CompanyGoodsOnWay.Organization, CompanyGoodsOnWay.InventoryOwnerAttribute) IN (
		|		SELECT
		|			StockSelection.Organization,
		|			StockSelection.InventoryOwnerAttribute
		|		FROM
		|			StockSelection)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance,
		|	CompanySafeStockBalance.QuantityByGBRNBalance 	AS QuantityByGBRNBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|		&CorrectionBoundary,
		|		(Organization, InventoryOwnerAttribute) IN (
		|			SELECT
		|				StockSelection.Organization,
		|				StockSelection.InventoryOwnerAttribute
		|			FROM
		|				StockSelection)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 						AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 		AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 							AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 			AS CountBalance,
		|	SUM(BalancesAtEndOfPeriod.QuantityByGBRNBalance) 	AS QuantityByGBRNBalance
		|INTO GroupedNegativeResiduals
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GroupedNegativeResiduals.Organization 				AS Organization,
		|	GroupedNegativeResiduals.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	GroupedNegativeResiduals.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	GroupedNegativeResiduals.CCDNumber 					AS CCDNumber,
		|	GroupedNegativeResiduals.CountBalance 			AS CountBalance,
		|	GroupedNegativeResiduals.QuantityByGBRNBalance 	AS QuantityByGBRNBalance,
		|	InventoryLocationAttributeKeys.Products 					AS Products,
		|	InventoryLocationAttributeKeys.Characteristic 					AS Characteristic,
		|	InventoryLocationAttributeKeys.Series 							AS Series,
		|	InventoryLocationAttributeKeys.Purpose 						AS Purpose,
		|	InventoryKinds.Contract 											AS Contract,
		|	InventoryKinds.GoodsOwner 										AS GoodsOwner
		|INTO Negative_Balance
		|FROM
		|	GroupedNegativeResiduals AS GroupedNegativeResiduals
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON GroupedNegativeResiduals.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON GroupedNegativeResiduals.InventoryOwnerAttribute = InventoryKinds.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BalancesAtEndOfPeriod.Organization 						AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 		AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 							AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 			AS CountBalance,
		|	SUM(BalancesAtEndOfPeriod.QuantityByGBRNBalance) 	AS QuantityByGBRNBalance
		|INTO GroupedSourceBalances
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|WHERE
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes IN (
		|		SELECT
		|			Negative_Balance.ItemsLocationAttributes
		|		FROM
		|			Negative_Balance)
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) > 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GroupedSourceBalances.Organization 				AS Organization,
		|	GroupedSourceBalances.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GroupedSourceBalances.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	GroupedSourceBalances.CCDNumber 					AS CCDNumber,
		|	InventoryLocationAttributeKeys.Products 				AS Products,
		|	InventoryLocationAttributeKeys.Characteristic 				AS Characteristic,
		|	InventoryLocationAttributeKeys.Series 						AS Series,
		|	InventoryLocationAttributeKeys.Purpose 					AS Purpose,
		|	InventoryKinds.Contract 										AS Contract,
		|	InventoryKinds.GoodsOwner 									AS GoodsOwner,
		|	InventoryKinds.InventoryType 										AS InventoryType,
		|	GroupedSourceBalances.CountBalance 			AS CountBalance,
		|	GroupedSourceBalances.QuantityByGBRNBalance 	AS QuantityByGBRNBalance
		|INTO RemnantsOfSources
		|FROM
		|	GroupedSourceBalances AS GroupedSourceBalances
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON GroupedSourceBalances.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
		|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON GroupedSourceBalances.InventoryOwnerAttribute = InventoryKinds.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Organization 									AS Organization,
		|	RemnantsOfSources.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CASE
		|		WHEN RemnantsOfSources.Organization = &Organization
		|			THEN RemnantsOfSources.InventoryOwnerAttribute
		|		ELSE UNDEFINED
		|	END 											AS InventoryOwnerAttribute,
		|	CASE
		|		WHEN RemnantsOfSources.InventoryType IN (&InventoryTypesExternalOwner)
		|			THEN RemnantsOfSources.GoodsOwner
		|		ELSE UNDEFINED
		|	END 											AS Owner,
		|	RemnantsOfSources.CCDNumber 						AS CCDNumber,
		|	RemnantsOfSources.CountBalance 			AS Count,
		|	RemnantsOfSources.QuantityByGBRNBalance 		AS QuantityByGBRN,
		|	RemnantsOfSources.Organization <> &Organization 	AS ReserveRequired
		|FROM
		|	RemnantsOfSources AS RemnantsOfSources
		|
		|ORDER BY
		|	RemnantsOfSources.Organization = &Organization DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Negative_Balance.Organization 				AS Organization,
		|	Negative_Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Negative_Balance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CASE
		|		WHEN &InventoryType IN (&InventoryTypesExternalOwner)
		|			THEN Negative_Balance.GoodsOwner
		|		ELSE UNDEFINED
		|	END 											AS Owner,
		|	Negative_Balance.CCDNumber 					AS CCDNumber,
		|	Negative_Balance.CountBalance 			AS Count,
		|	Negative_Balance.QuantityByGBRNBalance 	AS QuantityByGBRN
		|FROM
		|	Negative_Balance AS Negative_Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SourceStockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP StockSelection
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GroupedNegativeResiduals
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Negative_Balance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP GroupedSourceBalances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RemnantsOfSources";
	
	Query.SetParameter("InventoryTypesExternalOwner", Enums.InventoryTypes.InventoryTypesExternalOwner());
	Query.SetParameter("IncludingYourOwn",         True);
	Query.SetParameter("CorrectionBoundary",         New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",  		EndOfMonth(MonthOfCorrection));
	
	Return Query;

EndFunction

Function TypesOfOffsetOfBalancesOfExpandedBalance()
	
	Var TypeOfCredit, TypesOfOffsettingBalances;
	
	TypesOfOffsettingBalances = New ValueTable;
	TypesOfOffsettingBalances.Columns.Add("NameOfOffsetType");
	TypesOfOffsettingBalances.Columns.Add("PackageNumberReadyForDistribution");
	TypesOfOffsettingBalances.Columns.Add("PackageNumberNegativeBalances");
	TypesOfOffsettingBalances.Columns.Add("PropsNameNumberOfWH");
	TypesOfOffsettingBalances.Columns.Add("TheStructureOfTheSearch");
	
	TypeOfCredit                                  = TypesOfOffsettingBalances.Add();
	TypeOfCredit.NameOfOffsetType                    = "ByProductsOfOrganizations";
	TypeOfCredit.PackageNumberReadyForDistribution = 30;
	TypeOfCredit.PackageNumberNegativeBalances  = 31;
	TypeOfCredit.PropsNameNumberOfWH        = "Count";
	TypeOfCredit.TheStructureOfTheSearch                  = "ItemsLocationAttributes, Organization, Owner";
	
	Return TypesOfOffsettingBalances;

EndFunction

Function QueryNegativeBalanceAnalysisOfUnfoldedBalance(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		InventoriesServer.StopRegisteringRecordsOfCompanyGoodsInTransit("&CorrectionPeriod_") + 
		Common.QueryBatchSeparator() +
		
		"SELECT
		|	CompanyGoodsBalance.Organization 				AS Organization,
		|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanyGoodsBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanyGoodsBalance.CCDNumber 					AS CCDNumber,
		|	CompanyGoodsBalance.CountBalance 			AS CountBalance
		|INTO BalancesAtEndOfPeriod
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|		&CorrectionBoundary,
		|		Organization = &Organization
		|			AND ItemsLocationAttributes = &ItemsLocationAttributes
		|			AND InventoryOwnerAttribute IN (
		|				SELECT
		|					TTControlledInventoryTypes.Ref
		|				FROM
		|					TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanyGoodsBalance
		|
		|UNION ALL
		|
		|SELECT
		|	CompanyGoodsOnWay.Organization 					AS Organization,
		|	CompanyGoodsOnWay.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	CompanyGoodsOnWay.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	CompanyGoodsOnWay.CCDNumber 					AS CCDNumber,
		|	-CompanyGoodsOnWay.NumberIsReversed			AS CountBalance
		|FROM
		|	CompanyGoodsOnWay AS CompanyGoodsOnWay
		|WHERE
		|	CompanyGoodsOnWay.Period <= &CorrectionPeriod_
		|	AND CompanyGoodsOnWay.Organization = &Organization
		|	AND CompanyGoodsOnWay.ItemsLocationAttributes = &ItemsLocationAttributes
		|	AND CompanyGoodsOnWay.InventoryOwnerAttribute IN (
		|		SELECT
		|			TTControlledInventoryTypes.Ref
		|		FROM
		|			TTControlledInventoryTypes AS TTControlledInventoryTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	CompanySafeStockBalance.Organization 				AS Organization,
		|	CompanySafeStockBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CompanySafeStockBalance.InventoryOwnerAttribute 				AS InventoryOwnerAttribute,
		|	CompanySafeStockBalance.CCDNumber 					AS CCDNumber,
		|	CompanySafeStockBalance.CountBalance 			AS CountBalance
		|FROM
		|	AccumulationRegister.CompanySafeStock.Balance(
		|			&CorrectionBoundary,
		|			Organization = &Organization
		|				AND ItemsLocationAttributes = &ItemsLocationAttributes
		|				AND InventoryOwnerAttribute IN
		|					(SELECT
		|						TTControlledInventoryTypes.Ref
		|					FROM
		|						TTControlledInventoryTypes AS TTControlledInventoryTypes)) AS CompanySafeStockBalance
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	CCDNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CompanyGoodsOnWay
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	BalancesAtEndOfPeriod.Organization 					AS Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber 						AS CCDNumber,
		|	SUM(BalancesAtEndOfPeriod.CountBalance) 		AS CountBalance
		|FROM
		|	BalancesAtEndOfPeriod AS BalancesAtEndOfPeriod
		|
		|GROUP BY
		|	BalancesAtEndOfPeriod.Organization,
		|	BalancesAtEndOfPeriod.ItemsLocationAttributes,
		|	BalancesAtEndOfPeriod.InventoryOwnerAttribute,
		|	BalancesAtEndOfPeriod.CCDNumber
		|
		|HAVING
		|	SUM(BalancesAtEndOfPeriod.CountBalance) < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP BalancesAtEndOfPeriod";                    
	
	Query.SetParameter("ItemsLocationAttributes", SidedBalanceDimension);
	Query.SetParameter("Organization", 			    SidedBalanceCompany);
	Query.SetParameter("CorrectionBoundary", 	    New Boundary(EndOfMonth(MonthOfCorrection), BoundaryType.Including));
	Query.SetParameter("CorrectionPeriod_",          EndOfMonth(MonthOfCorrection));

	Return Query;

EndFunction

#EndRegion

#EndIf