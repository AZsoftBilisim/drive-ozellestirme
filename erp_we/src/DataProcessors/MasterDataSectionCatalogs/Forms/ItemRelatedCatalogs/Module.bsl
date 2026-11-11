

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ManagingElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region GeneralCatalogues

&AtClient
Procedure OpenProductKinds(Command)
	
	OpenForm("Catalog.ItemKinds.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenProductAccessGroups(Command)
	
	OpenForm("Catalog.ItemAccessGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenUnitsOfMeasure(Command)
	
	Filter = New Structure;
	Filter.Insert("Owner",PredefinedValue("Catalog.PackagingGroups.BasicUnitsOfMeasure"));
	CatalogFormParameters = New Structure("Filter", Filter);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ListForm",
		CatalogFormParameters,
		ThisForm);
		
EndProcedure

&AtClient
Procedure OpenPackagingSets(Command)
	
	OpenForm("Catalog.PackagingGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSeriesAccountingPolicies(Command)
	
	OpenForm("Catalog.BatchAccountingPolicies.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenWarehouseProductGroups(Command)
	
	OpenForm("Catalog.WarehouseGroupsOfItems.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenWarehousePackagingGroups(Command)
	
	OpenForm("Catalog.WarehousePackageGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure ToOpenTheSizesOfPackages(Command)
	
	OpenForm("Catalog.StandardSizesOfPackages.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPriceGroups(Command)
	
	OpenForm("Catalog.PriceGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSeasonalGroups(Command)
	
	OpenForm("Catalog.SeasonalGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenItemFinancialAccountingGroups(Command)

	OpenForm("Catalog.InventoryAccountingGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenGroupsOfAnalyticalProductAccounting(Command)
	
	OpenForm("Catalog.AnalyticalInventoryGroups.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenProductSegments(Command)
	
	OpenForm("Catalog.ProductSegments.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenExciseTaxClassifier(Command)
	
	OpenForm("Catalog.ExcisableGoodsCategories.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenExciseTaxesOfItem(Command)
	
	OpenForm("DataProcessor.FillExcisableGoodsCategories.Form.Workplace", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenVATRatesForItems(Command)
	
	OpenForm("InformationRegister.ProductsVATRates.Form.Workplace", , ThisForm);
	
EndProcedure

#EndRegion

&AtClient
Procedure ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	SystemSettingsClientLocalization.HandlingNavigationalLinkOfForm__ProductClassifiers(
		Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
		
EndProcedure

&AtClient
Procedure OpenTheHSClassifierURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Catalog.FEACN.ListForm", , ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()

	// Functional options
	BaseVersion 						 	 = GetFunctionalOption("BaseVersion");
	UseProductGroups         	 = GetFunctionalOption("UseItemAccessGroups");
	UseItemPackages       	 = GetFunctionalOption("UseItemPackages");
	UsePriceGroups              	 = GetFunctionalOption("UsePriceGroups");
	UseItemAccessGroups  	 = GetFunctionalOption("UseItemAccessGroups");
	UseItemsBatch          	 = GetFunctionalOption("UseItemsBatch");
	UseBinLocationWarehousing           	 = GetFunctionalOption("UseBinLocationWarehousing", New Structure);
	UseMultipleCompanies       	 = GetFunctionalOption("UseMultipleCompanies");
	UseMultipleCurrencies             	 = GetFunctionalOption("UseMultipleCurrencies");
	UseSeveralWarehouses           	 = GetFunctionalOption("UseSeveralWarehouses");
	UseRetailSales           	 = GetFunctionalOption("UseRetailSales");
	UseSeveralCashRegisters             = GetFunctionalOption("UseSeveralCashRegisters");
	UseSeasonalIndexes       	 = GetFunctionalOption("UseSeasonalIndexes");
	UseMultipleCashAccounts              	 = GetFunctionalOption("UseMultipleCashAccounts");
	UseMultipleBankAccounts	 = GetFunctionalOption("UseMultipleBankAccounts");
	UseAnalyticalAccountingGroups	 = GetFunctionalOption("UseAnalyticalInventoryGroups");
	UseProductSegments		 = GetFunctionalOption("UseProductSegments");
	UseFinancialAccountingGroups		 = GetFunctionalOption("UseFinancialAccountingGroups");
	UseImports			 = GetFunctionalOption("UseImports");
	UseSalesForExport			 = GetFunctionalOption("UseSalesForExport");
	UseExcisableGoods			 = GetFunctionalOption("UseExcisableGoods");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Warehouses.Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.UseBinLocationWarehousing
	|	AND NOT Warehouses.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	Warerooms.Ref
	|FROM
	|	Catalog.Warerooms AS Warerooms
	|WHERE
	|	Warerooms.UseBinLocationWarehousing";
	
	SetPrivilegedMode(True);
	UseBinLocationWarehousing = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	// Read right
	PackageAccessRights                    = AccessRight("View", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	RightOfAccessSetsOfPackages              = AccessRight("View", Metadata.Catalogs.PackagingGroups);
	AccessRightUnitsOfMeasurement            = AccessRight("View", Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	AccessRightOfProductAccessGroup   = AccessRight("View", Metadata.Catalogs.ItemAccessGroups);
	RightOfAccessWarehouseGroupsOfPackages     = AccessRight("View", Metadata.Catalogs.WarehousePackageGroups);
	RightOfAccessTypesOfProducts            = AccessRight("View", Metadata.Catalogs.ItemKinds);
	SeriesAccountingPolicyAccessRights          = AccessRight("View", Metadata.Catalogs.BatchAccountingPolicies);
	RightOfAccessStandardSizesOfPackages         = AccessRight("View", Metadata.Catalogs.StandardSizesOfPackages);
	RightOfAccessPriceGroups               = AccessRight("View", Metadata.Catalogs.PriceGroups);
	RightOfAccessSeasonalGroups              = AccessRight("View", Metadata.Catalogs.SeasonalGroups);
	AccessRightsOfAnalyticalAccountingGroup   = AccessRight("View", Metadata.Catalogs.AnalyticalInventoryGroups);
	AccessRightsProductSegments		= AccessRight("View", Metadata.Catalogs.ProductSegments);
	AccessRightOfFinancialAccountingGroup		= AccessRight("View", Metadata.Catalogs.InventoryAccountingGroups);
	RightOfAccessHSClassifiers			= AccessRight("View", Metadata.Catalogs.FEACN);
	
	RightOfAccessWarehouseGroupsOfProducts                 = AccessRight("View", Metadata.Catalogs.WarehouseGroupsOfItems);
	RightOfAccessWarehouseAccessGroupsProducts          = AccessRight("View", Metadata.Catalogs.ItemAccessGroups);
		
	OrganizationAccessRights = AccessRight("View", Metadata.Catalogs.Companies);
	CurrencyAccessRights      = AccessRight("View", Metadata.Catalogs.Currencies);
	RightOfAccessWarehouses      = AccessRight("View", Metadata.Catalogs.Warehouses);
	CashRegisterAccessRights    = AccessRight("View", Metadata.Catalogs.CashRegisters);
	
	RightOfAccessTypesOfContactInformation = AccessRight("View", Metadata.Catalogs.ContactInformationKinds);

	RightOfAccessVATRatesOfItems = AccessRight("View", Metadata.InformationRegisters.ProductsVATRates);
	RightOfAccessExciseCategories = AccessRight("View", Metadata.Catalogs.ExcisableGoodsCategories);
	RightOfAccessExciseItemExciseTaxes = AccessRight("View", Metadata.InformationRegisters.ExcisableGoodsCategories);
	
	//Products
	Items.GroupTheTypesOfItems.Visible = RightOfAccessTypesOfProducts;
	Items.GroupSeriesAccountingPolicies.Visible = UseItemsBatch
		And SeriesAccountingPolicyAccessRights;
	Items.UnitOfMeasurementGroup.Visible = AccessRightUnitsOfMeasurement;
	Items.GroupSetsOfPackages.Visible = UseItemPackages
		And RightOfAccessSetsOfPackages;
	Items.InventoryItemGroupsGroup.Visible = UseBinLocationWarehousing
		And RightOfAccessWarehouseGroupsOfProducts;
	Items.GroupWarehouseGroupsOfPackages.Visible = UseBinLocationWarehousing
		And RightOfAccessWarehouseGroupsOfPackages;
	Items.GroupPackagingStandardSizes.Visible = RightOfAccessStandardSizesOfPackages
		And UseItemPackages;
	Items.GroupPriceGroups.Visible = UsePriceGroups
		And RightOfAccessPriceGroups;
	Items.ItemAccessGroupGroup.Visible = UseItemAccessGroups
		And AccessRightOfProductAccessGroup;
	Items.GroupSeasonalGroups.Visible = UseSeasonalIndexes And RightOfAccessSeasonalGroups;
	Items.OpenGroupsOfAnalyticalProductAccounting.Visible = UseAnalyticalAccountingGroups
		And AccessRightsOfAnalyticalAccountingGroup;
	Items.ProductSegments.Visible = UseProductSegments And AccessRightsProductSegments;
	Items.OpenGroupsOfItemFinancialAccountingSettings.Visible = UseFinancialAccountingGroups And AccessRightOfFinancialAccountingGroup;
	
	SeveralKindsOfProducts = GetFunctionalOption("UseMultipleKindsOfProducts");
	Items.ItemKinds.Visible					= SeveralKindsOfProducts;
	Items.OpenProductKindGoods.Visible 		= Not SeveralKindsOfProducts;
	Items.OpenProductKindService.Visible 	= Not SeveralKindsOfProducts;
	
	Items.OpenTheHSClassifier.Visible = (UseImports
														Or UseSalesForExport
														Or UseTraceableImportedGoodsAccounting)
													And RightOfAccessHSClassifiers;
	
	SystemSettingsLocalization.SetAvailability_ProductClassifiers(ThisForm);
	
	Items.VATRateGroupOfItem.Visible = RightOfAccessVATRatesOfItems;
	Items.ExciseTaxesGroup.Visible                = RightOfAccessExciseCategories And UseExcisableGoods;
	Items.ExciseItemGroup.Visible    = RightOfAccessExciseItemExciseTaxes And UseExcisableGoods;
	
EndProcedure

#Region Other

&AtClient
Procedure OpenProductKindGoods(Command)
	
	Var_Key = GetPresetProductTypes(PredefinedValue("Enum.ItemsTypes.OwnGoods"),NStr("vi = 'Hàng hóa';
																					|ru = 'Товар';
																					|en = 'Product'; fa = 'کالا';
																					|it = 'Merce';
																					|pl = 'Towar';
																					|tr = 'Ürün'"));
	OpenForm("Catalog.ItemKinds.ObjectForm", New Structure("Key", Var_Key));
	
EndProcedure

&AtClient
Procedure OpenProductKindService(Command)
	
	Var_Key = GetPresetProductTypes(PredefinedValue("Enum.ItemsTypes.OperationService"),NStr("vi = 'Dịch vụ';
																							|ru = 'Услуга';
																							|en = 'Service'; fa = 'خدمت';
																							|it = 'Servizio';
																							|pl = 'Usługa';
																							|tr = 'Hizmet'"));
	OpenForm("Catalog.ItemKinds.ObjectForm", New Structure("Key", Var_Key));
	
EndProcedure

&AtServerNoContext
Function GetPresetProductTypes(ItemsType, Name)
	
	ArrayOfViews = New Array();
	
	Catalogs.ItemKinds.AddPresetProductType(ArrayOfViews, ItemsType, Name);
	
	If ArrayOfViews.Count() > 0 Then
		Return ArrayOfViews[0];
	Else
		Return Undefined;
	EndIf;

EndFunction

#EndRegion

#EndRegion
