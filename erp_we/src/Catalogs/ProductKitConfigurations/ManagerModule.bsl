#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function generates a table of the item's components.
//
// Parameters:
//  ProductKit	 - CatalogRef.ProductKitConfigurations - link to the configuration option.
//  Package			 - CatalogRef.PackagesAndUnitsOfMeasure		 - link to the packaging reference or undefined.
//  Count			 - Number											 - number, number of sets.
// 
// Returns:
//  ValueTable - table of components.
//
Function GetProductComponents(ProductKit, Package = Undefined, Count = 1) Export

	QueryText =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	&KitCount * Goods.NumberOfPackages / Goods.Ref.Count AS NumberOfPackages,
	|	&KitCount * Goods.Count / Goods.Ref.Count AS Count,
	|	Goods.CostShare AS CostShare
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|
	|ORDER BY
	|	Goods.LineNumber";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", ProductKit);
	Query.SetParameter("KitCount", Count);
	
	TableOfComponents = Query.Execute().Unload();
	
	Return TableOfComponents;

EndFunction

// The function returns the main configuration option.
//
// Parameters:
//  Products		 - CatalogRef.Products - 
//  Characteristic		 - CatalogRef.ItemsCharacteristics - 
// 
// Returns:
//  CatalogRef.ProductKitConfigurations - on the main configuration option.
//
Function GetBasicEquipment(Products, Characteristic) Export

	Query = New Query(
	"SELECT TOP 1
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.ProductKitConfigurations AS Table
	|WHERE
	|	Table.Owner = &Products
	|	AND Table.Characteristic = &Characteristic
	|	AND Table.Main
	|");
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	Else
		Result = Catalogs.ProductKitConfigurations.EmptyRef();
	EndIf;

	Return Result;

EndFunction

// The function generates an array of details for blocking editing
// 
// Returns:
//  Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Characteristic");
	Result.Add("Goods;GoodsInstallTheMainComponent,ProductsSetTheMainComponentContext,GoodsFill");
	Result.Add("NumberOfPackages");
	Result.Add("Package");
	Result.Add("PresentationOptionInPrintForms");
	Result.Add("PricingOption; PricingOption, ThePriceSettingOptionIsAssignedToTheSet");
	Result.Add("PriceDistributionOption");
	
	Return Result;

EndFunction

// The function checks whether the configuration option belongs to the nomenclature / characteristic,
//  and selects the main option.
//
// Parameters:
//  ProductKit	 - CatalogRef.ProductKitConfigurations - 
//  Products		 - CatalogRef.Products - 
//  Characteristic		 - CatalogRef.ItemsCharacteristics - 
// 
// Returns:
//  Structure - contains the following keys:
//    * BelongsToProductDescription - Boolean -
//    * MainConfigurationOption          - CatalogRef.ProductKitConfigurations - 
//
Function CheckWhetherConfigurationOptionBelongs(ProductKit, Products, Characteristic) Export

	QueryText = 
	"SELECT TOP 1
	|	1
	|FROM
	|	Catalog.ProductKitConfigurations AS Table
	|WHERE
	|	Table.Ref = &ProductKit
	|	AND Table.Owner = &Products
	|	AND Table.Characteristic = &Characteristic
	|;
	|///////////////////////////////////////////////////
	|SELECT TOP 1
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.ProductKitConfigurations AS Table
	|WHERE
	|	Table.Owner = &Products
	|	AND Table.Characteristic = &Characteristic
	|	AND Table.Main
	|";
	Query = New Query(QueryText);
	Query.SetParameter("ProductKit", ProductKit);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	ResultsArray = Query.ExecuteBatch();
	
	BelongsToProductDescription = Not ResultsArray[0].IsEmpty();

	Selection = ResultsArray[1].Select();
	If Selection.Next() Then
		MainConfigurationOption = Selection.Ref;
	Else
		MainConfigurationOption = Catalogs.ProductKitConfigurations.EmptyRef();
	EndIf;

	Return New Structure("BelongsToProductDescription, MainConfigurationOption",
					BelongsToProductDescription,
					MainConfigurationOption);
EndFunction

// Adds a request to the request package to get the data needed to fill in the item configuration option.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextOfItemConfigurationOption(StructureOfActions, QueryDetails, CachedValues) Export
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckCompleteConfigurationOptionByOwner",
		StructureOfActions,
		CachedValues) Then
	
		QueryText = "
			|SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			Catalog.ProductKitConfigurations AS Table
			|		WHERE
			|			Table.Ref = DataSource.ProductKit
			|			AND Table.Owner = DataSource.Products
			|			AND Table.Characteristic = DataSource.Characteristic) AS BelongsToProductDescription
			|FROM
			|	TTDataSource AS DataSource";
		
		QueryDetails.QueriesTexts.Add(QueryText, "BelongingOfConfigurationOptionToItemCharacteristic");
		
		QueryText = "
			|SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CatProductKitConfigurations.Ref AS MainConfigurationOption
			|FROM
			|	TTDataSource AS DataSource
			|		LEFT JOIN Catalog.ProductKitConfigurations AS CatProductKitConfigurations
			|		ON CatProductKitConfigurations.Owner = DataSource.Products
			|			AND CatProductKitConfigurations.Characteristic = DataSource.Characteristic
			|			AND CatProductKitConfigurations.Main";
		
		QueryDetails.QueriesTexts.Add(QueryText, "MainConfigurationOption");
		
	EndIf;
	
EndProcedure

// Updates the number of components in the table part by the known number of sets and configuration option.
//
// Parameters:
//  TableOfComponents - FormDataCollection	 - Tabular part of the Assembly order or the "product Assembly" document.
//  KitCount - Number				 - for this number of sets, data on components for the configuration option will be obtained.
//  ProductKit	 - CatalogRef.ProductKitConfigurations - Configuration option.
//
Procedure UpdateNumberOfComponentsByNumberOfSets(TableOfComponents, KitCount, ProductKit) Export

	TableOfConfigurationOptions = GetProductComponents(ProductKit, , KitCount);

	TableOfConfigurationOptions.GroupBy("Products, Characteristic, Package", "Count, NumberOfPackages");
	TableOfConfigurationOptions.Indexes.Add("Products, Characteristic, Package");

	// Let's determine the excess quantity according to the configuration option relative to the document.
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Package");
	UBound = TableOfComponents.Count() - 1;
	For Counter = 0 To UBound Do

		IndexOf = UBound - Counter;
		TSRow = TableOfComponents[IndexOf];

		FillPropertyValues(TheStructureOfTheSearch, TSRow);
		ComponentLines = TableOfConfigurationOptions.FindRows(TheStructureOfTheSearch);
		If ComponentLines.Count() = 0 Then //there is no component in the configuration option
			Continue;
		EndIf;

		Accessories = ComponentLines[0];
		If Accessories.Count = 0 Then

			TableOfComponents.Delete(IndexOf);

		Else

			OptionBalance = Accessories.Count - TSRow.Count;

			If OptionBalance >= 0 Then
				Accessories.Count = OptionBalance;
				Accessories.NumberOfPackages = Accessories.NumberOfPackages - TSRow.NumberOfPackages;
			Else
				TSRow.Count         = Accessories.Count;
				TSRow.NumberOfPackages = Accessories.NumberOfPackages;
				Accessories.Count = 0;
			EndIf;

		EndIf;

	EndDo;

	// Update the quantity in the existing rows.
	For Each TSRow In TableOfComponents Do

		FillPropertyValues(TheStructureOfTheSearch, TSRow);
		ComponentLines = TableOfConfigurationOptions.FindRows(TheStructureOfTheSearch);
		If ComponentLines.Count() = 0 Then
			Continue;
		EndIf;

		Accessories = ComponentLines[0];
		If Accessories.Count > 0 Then
			TSRow.Count         = TSRow.Count + Accessories.Count;
			TSRow.NumberOfPackages = TSRow.NumberOfPackages + Accessories.NumberOfPackages;
			Accessories.Count = 0;
		EndIf;

	EndDo;

EndProcedure

// Initializes the parameters for verifying the correctness of the set.
//
// Parameters:
//	Object - CatalogObject.ProductKitConfigurations,
//				This Formstructure is a configuration option for which you need to get
//										the content verification parameters.
//
// Returns:
//	Structure - See AccountingForTraceableGoodsLocalization.SetValidationParameters.
//
Function SetValidationParameters(Object) Export
	
	CheckParameters = AccountingForTraceableGoodsLocalization.SetValidationParameters();
	FillPropertyValues(CheckParameters, Object);
	
	CheckParameters.Date			= CurrentSessionDate();
	CheckParameters.Products	= Object.Owner;
	
	Return CheckParameters;
	
EndFunction

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" And Parameters.Property("Key") Then
		
		Query = New Query("
		|SELECT
		|	ProductKitConfigurations.Owner.ItemsType AS ItemsType
		|FROM
		|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|WHERE
		|	ProductKitConfigurations.Ref = &Ref");
		
		Query.SetParameter("Ref", Parameters.Key);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		ItemsType  = Selection.ItemsType;
		If ItemsType = Enums.ItemsTypes.Set Then
			StandardProcessing = False;
			SelectedForm = "Catalog.ProductKitConfigurations.Form.SetComposition";
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
#EndIf