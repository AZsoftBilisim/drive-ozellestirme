#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the excise category for the specified item as of the date by country.
// If the item is not excisable, then the excisable item attribute is set.
//
// Parameters:
//  FillParameters - Structure:
//     * ItemList - Array of CatalogRef.Products - a list of items or the address of the temporary storage containing the item;
//     * Period - Date - the start date of the specified category for the item;
//     * Country - CatalogRef.WorldCountries - Country of category action;
//     * ExcisableGoodsCategory - CatalogRef.ExcisableGoodsCategories - excise category.
//
Procedure SetExciseCategoryOfItem(FillParameters) Export
	
	If ValueIsFilled(FillParameters.ItemList)
		And TypeOf(FillParameters.ItemList) = Type("Array") Then
		
		For Each CurrentProducts In FillParameters.ItemList Do
			AddRegisterEntry(FillParameters.Period,
				CurrentProducts,
				FillParameters.Country,
				FillParameters.ExcisableGoodsCategory,
				0);
		EndDo;
			
	EndIf;
	
EndProcedure

// Sets the conversion ratio from the storage unit of the item to the unit of the excise category.
//
// Parameters:
//  FillParameters - Structure:
//     * ItemList - Array of Structure - a list of items or the address of the temporary storage containing the item:
//        * AutoConversionRatio - Number - the coefficient of automatic conversion of units;
//        * Products - CatalogRef.Products - The item for which you need to set the coefficient;
//     * AutocompletionOfConversionRatio - Boolean - flag for automatic calculation of the conversion ratio;
//     * Period - Date - the start date of the specified category for the item;
//     * Country - CatalogRef.WorldCountries - Country of category action;
//     * ConversionFactor_ - Number - the conversion ratio entered by the user.
//
Procedure SetConversionRatioForList(FillParameters) Export
	
	If ValueIsFilled(FillParameters.ItemList)
		And TypeOf(FillParameters.ItemList) = Type("Array") Then
		
		For Each CurrentRow In FillParameters.ItemList Do
			If FillParameters.AutocompletionOfConversionRatio Then
				ConversionFactor_ = CurrentRow.AutoConversionRatio;
			Else
				ConversionFactor_ = FillParameters.ConversionFactor_;
			EndIf;
			AddRegisterEntry(FillParameters.Period,
				CurrentRow.Products,
				FillParameters.Country,
				CurrentRow.ExcisableGoodsCategory,
				ConversionFactor_);
		EndDo;
			
	EndIf;
	
EndProcedure

// Determines the number of excisable items in the item array for the specified country.
// 
// Parameters:
//  Products - Array of CatalogRef.Products - 
//  Country - CatalogRef.WorldCountries - 
//  Period - Date, Undefined - The period for which it is necessary to determine whether the item
//  							belongs to the excise category.
// 
// Returns:
//  Number - 
Function NumberOfExcisableItems(Products, Country, Period = Undefined) Export
	
	NumberOfExcisableItems = 0;
	
	If ValueIsFilled(Products) Then
	
		Query = New Query;
		Query.SetParameter("Products", Products);
		Query.SetParameter("Country", Country);
		Query.SetParameter("Period", Period);
		Query.Text =
		"SELECT
		|	ISNULL(COUNT(*), 0) AS NumberOfExcisableItems
		|FROM
		|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, Products IN (&Products)
		|	AND Country = &Country) AS ExcisableGoodsCategoriesSliceLast
		|WHERE
		|	ExcisableGoodsCategoriesSliceLast.ExcisableGoods";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			NumberOfExcisableItems = Selection.NumberOfExcisableItems;
		EndIf;
		
	EndIf;
	
	Return NumberOfExcisableItems;
	
EndFunction

// Resets the excisable category and the excisable item attribute for the specified item as of the date by country.
//
// Parameters:
//  FillParameters - Structure:
//     * ItemList - Array of CatalogRef.Products - a list of items or the address of the temporary storage containing the item;
//     * Period - Date - the date from which the item becomes non-excisable;
//     * Country - CatalogRef.WorldCountries - the country for which the item ceases to be excisable.
//
Procedure ClearExcisableItemAttribute(FillParameters) Export

	If ValueIsFilled(FillParameters.ItemList)
		And TypeOf(FillParameters.ItemList) = Type("Array") Then
			
		For Each CurrentProducts In FillParameters.ItemList Do
			AddRegisterEntry(FillParameters.Period,
				CurrentProducts,
				FillParameters.Country,
				Undefined,
				0);
		EndDo;
			
	EndIf;

EndProcedure

// Loads the excisable item attribute.
//
// Parameters:
//  Products - CatalogRef.Products - nomenclature;
//  Country - CatalogRef.WorldCountries - country of validity of the excisable attribute;
//  ExcisableGoods - Boolean - a sign that the product is excisable.
//
Procedure UploadExcisableItemAttribute(Products, Country, ExcisableGoods) Export
	
	Period = CurrentSessionDate();
	FullRegisterName = Metadata.InformationRegisters.ExcisableGoodsCategories.FullName();
	
	BeginTransaction();
	
	Try
		
		SelectionByParameters = New Structure();
		SelectionByParameters.Insert("Products", Products);
		SelectionByParameters.Insert("Country", Country);
		
		Block = New DataLock;
		LockItem = Block.Add(FullRegisterName);
		LockItem.SetValue("Products", Products);
		LockItem.SetValue("Country", Country);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		LatestData = InformationRegisters.ExcisableGoodsCategories.GetLast(Period, SelectionByParameters);
		
		If LatestData.ExcisableGoods <> ExcisableGoods Then
			RecordManager = CreateRecordManager();
			RecordManager.Products = Products;
			RecordManager.Period = Period;
			RecordManager.Country = Country;
			RecordManager.ExcisableGoods = ExcisableGoods;
			RecordManager.Write(True);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorTemplate = NStr("vi = 'Không thể chuyển dấu hiệu %1 theo mặt hàng ""%2"":
									|
									|do nguyên nhân:
									|%4';
									|ru = 'Не удалось перенести признак %1 по номенклатуре ""%2"":
									|
									|по причине:
									|%4';
									|en = 'Cannot transfer the %1 flag for the ""%2"" item:
									|
									|Reason:
									|%4'; fa = 'Cannot transfer the %1 flag for the ""%2"" item:
									|
									|Reason:
									|%4';
									|it = 'Cannot transfer the %1 flag for the ""%2"" item:
									|
									|Reason:
									|%4';
									|pl = 'Cannot transfer the %1 flag for the ""%2"" item:
									|
									|Reason:
									|%4';
									|tr = '""%2"" öğesi kapsamında %1 işareti aktarılamadı:
									|
									|nedeni:
									|%4'");
		
		ErrorText = StrTemplate(ErrorTemplate,
									Metadata.Catalogs.Products.Attributes.DeleteExcisableGoods.Presentation(),
									Products,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.InformationRegisters.ErrorsWhenExecutingDeferredJobs,,
			ErrorText);
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

Procedure AddRegisterEntry(Period, Products, Country, ExcisableGoodsCategory, ConversionFactor_)
	
	RecordSet = InformationRegisters.ExcisableGoodsCategories.CreateRecordSet();
	RecordSet.Filter.Period.Set(Period);
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Country.Set(Country);
	
	NewRecord = RecordSet.Add();
	
	If ValueIsFilled(ExcisableGoodsCategory) Then
		NewRecord.ExcisableGoods = True;
	Else
		NewRecord.ExcisableGoods = False;
	EndIf;
	
	NewRecord.Period = Period;
	NewRecord.Products = Products;
	NewRecord.Country = Country;
	NewRecord.ExcisableGoodsCategory = ExcisableGoodsCategory;
	NewRecord.ConversionFactor_ = ConversionFactor_;
	
	RecordSet.Write();
	
EndProcedure

// Deletes an entry from the register.
//
// Parameters:
//  Period - Date
//  Products - CatalogRef.Products
//  Country - CatalogRef.WorldCountries
//
Procedure DeleteRecord(Period, Products, Country) Export
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Period.Set(Period);
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Country.Set(Country);
	RecordSet.Write();
	
EndProcedure

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ExcisableGoodsCategories.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.19";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("de901df9-908e-4a93-9ed3-b8c1277e9a11");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.ExcisableGoodsCategories.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = StrTemplate(NStr("vi = 'Chuyển dấu hiệu ""%1"" từ danh mục ""%2"" vào biểu ghi ""%3"".';
										|ru = 'Переносит признак ""%1"" из справочника ""%2"" в регистр ""%3"".';
										|en = 'Transfers the ""%1"" flag from the ""%2"" catalog to the ""%3"" register.'; fa = 'Transfers the ""%1"" flag from the ""%2"" catalog to the ""%3"" register.';
										|it = 'Transfers the ""%1"" flag from the ""%2"" catalog to the ""%3"" register.';
										|pl = 'Transfers the ""%1"" flag from the ""%2"" catalog to the ""%3"" register.';
										|tr = '""%1"" işaretini ""%2"" kataloğunda ""%3"" kaydına aktarır.'"),
	Metadata.Catalogs.Products.Attributes.DeleteExcisableGoods.Presentation(),
	Metadata.Catalogs.Products.Presentation(),
	Metadata.InformationRegisters.ExcisableGoodsCategories.Presentation());
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.Products.FullName());
	ItemsToRead.Add(Metadata.Catalogs.Companies.FullName());
	ItemsToRead.Add(Metadata.Constants.UseMultiCountryAccounting.FullName());
	ItemsToRead.Add(Metadata.Constants.MainCountry.FullName());	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.ExcisableGoodsCategories.FullName());
	Editable1.Add(Metadata.Constants.UseExcisableGoods.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.ExcisableGoodsCategories.FullName());
	ToLock.Add(Metadata.Constants.UseExcisableGoods.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = Metadata.Catalogs.Products.FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ProductData_1.Ref AS Ref
	|FROM
	|	Catalog.Products AS ProductData_1
	|		LEFT JOIN InformationRegister.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|		ON (ProductData_1.Ref = ExcisableGoodsCategories.Products)
	|WHERE
	|	ProductData_1.DeleteExcisableGoods
	|	AND NOT ProductData_1.DeletionMark
	|	AND ExcisableGoodsCategories.Products IS NULL";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = Metadata.Catalogs.Products.FullName();
	
	SelectedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	ProgressMarkParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	
	If SelectedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(Metadata.Constants.UseExcisableGoods.FullName());
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Constants.UseExcisableGoods.Set(True);
		
		CommitTransaction();

	Except
		
		RollbackTransaction();
		
		ErrorTemplate = NStr("vi = 'Không thể đặt hằng ""%1"":
									|Hàng đợi: ""%2""
									|
									|do nguyên nhân:
									|%3';
									|ru = 'Не удалось установить константу ""%1"":
									|Очередь: ""%2""
									|
									|по причине:
									|%3';
									|en = 'Cannot set the ""%1"" constant:
									|Queue: ""%2""
									|
									|Reason:
									|%3'; fa = 'Cannot set the ""%1"" constant:
									|Queue: ""%2""
									|
									|Reason:
									|%3';
									|it = 'Cannot set the ""%1"" constant:
									|Queue: ""%2""
									|
									|Reason:
									|%3';
									|pl = 'Cannot set the ""%1"" constant:
									|Queue: ""%2""
									|
									|Reason:
									|%3';
									|tr = '""%1"" sabiti ayarlanamadı:
									|Sıra: ""%2""
									|
									|nedeni:
									|%3'");
		
		ErrorText = StrTemplate(ErrorTemplate,
									Metadata.Constants.UseExcisableGoods.FullName(),
									Parameters.Queue,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.InformationRegisters.ErrorsWhenExecutingDeferredJobs,,
			ErrorText);
			
		Parameters.ProcessingCompleted = False;
		Return;
		
	EndTry;
	
	FullRegisterName = Metadata.InformationRegisters.ExcisableGoodsCategories.FullName();
	
	If Constants.UseMultiCountryAccounting.Get() Then
		
		Query = New Query;
		Query.Text = "
		|SELECT DISTINCT
		|	OrganizationData_.RegistrationCountry AS RegistrationCountry
		|FROM
		|	Catalog.Companies AS OrganizationData_
		|WHERE
		|	NOT OrganizationData_.DeletionMark
		|	AND OrganizationData_.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)";
		
		CountriesOfRegistration = Query.Execute().Unload().UnloadColumn("RegistrationCountry");
		
	Else
		
		CountriesOfRegistration = New Array();
		CountriesOfRegistration.Add(Constants.MainCountry.Get());
		
	EndIf;
	
	DateEmpty = Date(1,1,1);
	
	For Each DataString1 In SelectedData Do
		
		BeginTransaction();
		
		Try
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Products.Set(DataString1.Ref);
			RecordSet.Filter.Period.Set(DateEmpty);
			
			For Each RegistrationCountry In CountriesOfRegistration Do
				
				Block = New DataLock;
				LockItem = Block.Add(FullRegisterName);
				LockItem.SetValue("Products", DataString1.Ref);
				LockItem.SetValue("Country", RegistrationCountry);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				NewRecord = RecordSet.Add();
				NewRecord.Period = DateEmpty;
				NewRecord.Products = DataString1.Ref;
				NewRecord.Country = RegistrationCountry;
				NewRecord.ExcisableGoods = True;
				
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			InfobaseUpdate.MarkProcessingCompletion(DataString1.Ref, ProgressMarkParameters);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorTemplate = NStr("vi = 'Không thể chuyển dấu hiệu %1 theo mặt hàng ""%2"":
										|Hàng đợi: ""%3""
										|
										|do nguyên nhân:
										|%4';
										|ru = 'Не удалось перенести признак %1 по номенклатуре ""%2"":
										|Очередь: ""%3""
										|
										|по причине:
										|%4';
										|en = 'Cannot transfer the %1 flag for the ""%2'' item:
										|Queue: ""%3""
										|
										|Reason:
										|%4'; fa = 'Cannot transfer the %1 flag for the ""%2'' item:
										|Queue: ""%3""
										|
										|Reason:
										|%4';
										|it = 'Cannot transfer the %1 flag for the ""%2'' item:
										|Queue: ""%3""
										|
										|Reason:
										|%4';
										|pl = 'Cannot transfer the %1 flag for the ""%2'' item:
										|Queue: ""%3""
										|
										|Reason:
										|%4';
										|tr = '""%2"" öğesi kapsamında %1 işareti aktarılamadı:
										|Sıra: ""%3""
										|
										|nedeni:
										|%4'");
			
			ErrorText = StrTemplate(ErrorTemplate,
										Metadata.Catalogs.Products.Attributes.DeleteExcisableGoods.Presentation(),
										DataString1.Ref,
										Parameters.Queue,
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.InformationRegisters.ErrorsWhenExecutingDeferredJobs,,
				ErrorText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
