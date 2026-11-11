
#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If ValueIsFilled(Data.JointApplicationOption) And Not ValueIsFilled(Data.Description) Then
		StandardProcessing = False;
		Presentation = Data.JointApplicationOption;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("IsFolder");
	Fields.Add("JointApplicationOption");
	Fields.Add("Description");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Gets the object's details that need to be blocked from being changed.
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("DiscountMarkupCurrency");
	Result.Add("JointApplicationOption");
	Result.Add("OptionOfJointApplicationResultCalculation");
	Result.Add("PriceKind");
	Result.Add("DiscountMarkupValue");
	Result.Add("GiftSegment");
	Result.Add("MethodsOfProviding;WayToProvideDiscountMarkUp,MethodOfGrantingBonusPoints,ShowTheFormForExternalProcessingSettings,ShowTheExternalProcessingSettingsForm,ClarificationByPriceGroupsViewAmount");
	Result.Add("Managed;DestinationMethod");
	Result.Add("DiscountMarkupConditions;DiscountMarkupConditionsSelectTerms,TermsOfServiceTermsOfServiceBonuses,TheConditionsForGrantingAGroupToCreate");
	Result.Add("PriceGroups");
	Result.Add("Parent");
	Result.Add("MessageText");
	Result.Add("LoyaltyCardKind");
	Result.Add("UseMultiplier");
	Result.Add("DiscountConditionByQuantity");
	Result.Add("RoundingPrecision");
	Result.Add("SmartRounding");
	Result.Add("RoundOffOption");
	Result.Add("DiscountApplicationMethod");
	Result.Add("DestinationMethod;TheMethodOfAssigningManually,TheMethodOfAssigningAutomatically");
	Result.Add("LoyaltyProgram");
	Result.Add("ActionPeriod;UseValidityPeriod");
	Result.Add("NumberOfValidityPeriods");
	Result.Add("PeriodOfActionStartDelay;UseActionStartDelay");
	Result.Add("NumberOfActionStartDelayPeriods");
	Result.Add("ItemFilterOption;AdditionalSelectionPresentation,FilterPresentation,ProductSegment,ItemList");
	Result.Add("ApplyMultiplicationWithinParentGroup");
	Result.Add("ApplyVariants");
	Return Result;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region RootGroup
	Item = Items.Add();
	Item.PredefinedDataName = "RootGroup";
	Item.Description = NStr("vi = 'Nhóm gốc';
							|ru = 'Корневая группа';
							|en = 'Root group'; fa = 'Root group';
							|it = 'Gruppo principale';
							|pl = 'Podstawowa grupa';
							|tr = 'Kök grup'", Common.DefaultLanguageCode());
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.DiscountsMarkups - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion

#Region Private

// Fills in the predefined element of the "Discounts (mark-UPS)"directory.
//
Procedure FillInPredefinedElements() Export
	
	CatalogObject = Catalogs.DiscountsMarkups.RootGroup.GetObject();
	CatalogObject.JointApplicationOption = Enums.OptionsOfJointUsageOfDiscountsAndMarkups.Max;
	CatalogObject.OptionOfJointApplicationResultCalculation = Enums.OptionsOfJointApplicationResultCalculation.ByLine;
	InfobaseUpdate.WriteData(CatalogObject);
	
EndProcedure

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.DiscountsMarkups.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.65";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("c5c85890-b0f4-11f0-8de9-0242ac120002");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.DiscountsMarkups.RegisterDataToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật các truy vấn được lưu trong bộ nhớ đệm cho chiết khấu/phụ thu';
							|ru = 'Обновление кэшированных запросов для скидок/наценок';
							|en = 'Update cached queries for discounts (markups)'; fa = 'Update cached queries for discounts (markups)';
							|it = 'Update cached queries for discounts (markups)';
							|pl = 'Update cached queries for discounts (markups)';
							|tr = 'İndirim/ek ücret için önbelleğe alınmış sorguların güncellenmesi'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.DiscountsMarkups.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.DiscountsMarkups.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.DiscountsMarkups.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToUpgradeToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Catalog.DiscountsMarkups";
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query(
		"SELECT
		|	DiscountsMarkups.Ref AS Ref
		|FROM
		|	Catalog.DiscountsMarkups AS DiscountsMarkups
		|WHERE
		|	NOT DiscountsMarkups.DeleteUpdatedToReceiveBalancesIncludingGoodsUnderControl
		|	AND NOT DiscountsMarkups.IsFolder
		|	AND NOT DiscountsMarkups.MethodsOfProviding IN(
		|		SELECT
		|			AdditionalReportsAndDataProcessors.Ref AS Ref
		|		FROM
		|			Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors)");
	
	RegisteredItems = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, RegisteredItems);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Catalog.DiscountsMarkups";
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
