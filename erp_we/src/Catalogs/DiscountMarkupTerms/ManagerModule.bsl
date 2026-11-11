#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("DiscountMarkupCondition");
	Result.Add("OptionOfCumulativeQuantityDiscountPeriodDetermination");
	
	Result.Add("AccumulationOption");
	Result.Add("CriteriaOfApplicationLimitationForSalesVolume");
	Result.Add("RestrictionCurrency");
	Result.Add("PaymentSchedule");
	Result.Add("PaymentMethod");
	Result.Add("RestrictionConditionValue");
	Result.Add("ProductSegmentRestrictions");
	Result.Add("AccumulationPeriod");
	Result.Add("ComparisonTypeSSL");
	Result.Add("UsersGroup");
	Result.Add("TimeOfValidity");
	Result.Add("LoyaltyCardKind");
	Result.Add("NumberOfAccumulationPeriods");
	Result.Add("PartnersSegment");
	Result.Add("ItemFilterOption");
	Result.Add("IncludeCurrentSaleInAccumulatedSalesVolume");
	Result.Add("NumberOfDaysAfterBirthday");
	Result.Add("NumberOfDaysBeforeBirthday");

	Return Result;

EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.DiscountMarkupTerms.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.65";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("5e4001a6-c38b-11f0-8de9-0242ac120002");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.UpdateDataFillingProcedure = "Catalogs.DiscountMarkupTerms.RegisterDataToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật các truy vấn được lưu trong bộ nhớ đệm cho điều kiện cho phép chiết khấu/phụ thu';
							|ru = 'Обновление кэшированных запросов для условий предоставления скидок/наценок';
							|en = 'Update cached queries for discount (markup) terms'; fa = 'Update cached queries for discount (markup) terms';
							|it = 'Update cached queries for discount (markup) terms';
							|pl = 'Update cached queries for discount (markup) terms';
							|tr = 'İndirim/ek ücret uygulanma koşulları için önbelleğe alınmış sorguların güncellenmesi'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.DiscountMarkupTerms.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.DiscountMarkupTerms.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.DiscountMarkupTerms.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToUpgradeToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Catalog.DiscountMarkupTerms";
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query(
		"SELECT
		|	DiscountMarkupTerms.Ref AS Ref
		|FROM
		|	Catalog.DiscountMarkupTerms AS DiscountMarkupTerms
		|WHERE
		|	NOT DiscountMarkupTerms.DeleteUpdatedToReceiveBalancesIncludingGoodsUnderControl
		|	AND NOT DiscountMarkupTerms.IsFolder
		|	AND DiscountMarkupTerms.DiscountMarkupCondition <> VALUE(Enum.DiscountMarkupTerms.ExternalDataProcessor)");
	
	RegisteredItems = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, RegisteredItems);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Catalog.DiscountMarkupTerms";
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	For Each CatalogItem In UpdatedData Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", CatalogItem.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = CatalogItem.Ref.GetObject();
			
			If CatalogObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(CatalogItem.Ref);
			Else
				
				AppealToBalanceIsOld = "LEFT JOIN WarehouseStockBalanceOverridable ON TRUE";  // @query-part-1
				DataCompositionSettings = CatalogObject.StorageOfDataCompositionSettings.Get();
				If ValueIsFilled(DataCompositionSettings)
						And TypeOf(DataCompositionSettings) = Type("Structure")
						And DataCompositionSettings.Property("Query")
						And TypeOf(DataCompositionSettings.Query) = Type("Structure")
						And DataCompositionSettings.Query.Property("QueryText")
						And TypeOf(DataCompositionSettings.Query.QueryText) = Type("String")
						And StrFind(DataCompositionSettings.Query.QueryText, AppealToBalanceIsOld) > 0 Then
						
					DiscountsMarkupsServer.UpdateCachedRequest(CatalogObject);
					
				EndIf;
				CatalogObject.DeleteUpdatedToReceiveBalancesIncludingGoodsUnderControl = True;
				InfobaseUpdate.WriteObject(CatalogObject);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CatalogItem.Ref);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
