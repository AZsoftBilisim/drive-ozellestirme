#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning


// Gets the object's details that need to be blocked from being changed
//
// Returns:
//	Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("PriceCurrency; SpecifyingCurrenciesByPriceGroupPresentation");
	Result.Add("PriceIncludesVAT");
	Result.Add("UseForWholesaleToCustomers");
	Result.Add("UseForRetailSalesToCustomers");
	Result.Add("UseForIntercompanySales");
	Result.Add("AuxiliaryPrice");
	Result.Add("Purpose;OwnerOfAnIndividualPriceTypePresentation");
	Result.Add("UseForIssuingProductsWorksAndServicesAtFixedCost");
	Result.Add("UseWhileTransferringProductsToMaterialProvider");
	Result.Add("PricingMethod;ParametersOfTheCalculationType,DepthOfDataAnalysis,DataCompositionSchemaPresentation");
	Result.Add("Id");
	Result.Add("DataCompositionSchema;SettingsComposerPresentation,EditDataCompositionSchema");
	
	Result.Add("RoundOffOption;RoundingMethod,RoundingMethodIsSimplified,TurnOffAdvancedMode,EnableAdvancedMode");
	Result.Add("ThresholdOnPriceIncreaseFor;ThresholdOnPriceDecreaseBy,UseTriggerThresholds");
	Result.Add("Formula;CommandPanelFormulaFormulaConstructor");
	
	Result.Add("PriceGroups; FormulasCurLineFormulaConstructor,ClarificationByPriceGroupPresentation");
	Result.Add("Thresholds; RefinementOfResponseThresholdsPresentation");
	Result.Add("PercentRateOfManualDiscount; GroupBasicPercentagesOfDiscountsMargins,UseDiscountMarkUpPercentages");
	Result.Add("Formulae");
	Result.Add("PriceRoundingRules");
	Result.Add("BasicPriceType");
	Result.Add("Markup;ExtraChargeOrDiscount, ModuleMarkUp");
	Result.Add("LimitItemFilter; FilterPresentation");
	Result.Add("DisablePriceEditingOutsideFilter");
	
	Result.Add("RoundingPrecision");
	Result.Add("Round; UseAdvancedRoundingSetting,RoundingPrecision,RoundOffOption,RoundingConstructor,RefinementOfRoundingSettingsPresentation");
	Result.Add("SetPriceDuringGeneration");
	
	Result.Add("ParametersOfPriceSettingMethod; ParametersOfPriceSettingMethodCustomType");
	Result.Add("VATRates; OptionForSpecifyingVATRates, Country, VATRate");

	Return Result;

EndFunction

// Defines the default price type
//
// Parameters:
//	PriceKind -  Undefined, CatalogRef.TypesOfPrices - Selection structure, where the Key is the name of the item and the Value is the value of the item.
//	Filters -  Structure - Selection structure, where the Key is the name of the item and the Value is the value of the item.
//
// Returns:
//	CatalogRef.TypesOfPrices - the found type of prices.
//
Function DefaultPriceType(Val PriceKind, Filters = Undefined) Export
	
	If ValueIsFilled(PriceKind) Then
		Return PriceKind;
	EndIf;
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	TypesOfPrices.Ref AS PriceKind
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT TypesOfPrices.DeletionMark
	|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
	|");
	
	If Filters <> Undefined Then
		For Each Filter In Filters Do
			Query.Text = Query.Text + "
				|	AND TypesOfPrices." + Filter.Key + " = &" + Filter.Key;
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		PriceKind = Selection.PriceKind;
	Else
		PriceKind = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
	Return PriceKind;

EndFunction

// Defines the default price type and whether the VAT price is included.
// The type of price is determined only if it is the only one in the information security system.
// The inclusion of prices in VAT is determined by a single type of price, the same value in all types of prices, or by
// the statistics of the document.
//
// Parameters:
//	Filters -  Structure - Selection structure, where the Key is the name of the item and the Value is the value of the item
//	LinkForStatistics - DocumentRef - Link to the document to determine statistics based on it.
//
// Returns:
//	Structure - The type of price and the sign of the price includes the following.
//
Function PriceTypeAndPriceIncludesVATAttributeByDefault(Filters = Undefined, LinkForStatistics = Undefined) Export
	
	AttributesStructure1 = New Structure("PriceKind, PriceIncludesVAT");
	
	Query = New Query("
	|SELECT ALLOWED
	|	TypesOfPrices.Ref AS PriceKind,
	|	TypesOfPrices.PriceIncludesVAT
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT TypesOfPrices.DeletionMark
	|");
	
	If Filters <> Undefined Then
		For Each Filter In Filters Do
			Query.Text = Query.Text + "
				|	AND TypesOfPrices." + Filter.Key + " = &" + Filter.Key;
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	Else
		
		PriceIncludesVAT = Undefined;
		While Selection.Next() Do
			If PriceIncludesVAT = Undefined Then
				PriceIncludesVAT = Selection.PriceIncludesVAT;
			ElsIf PriceIncludesVAT <> Selection.PriceIncludesVAT Then
				PriceIncludesVAT = Undefined;
				Break;
			EndIf;
		EndDo;
		
		If PriceIncludesVAT = Undefined
			And LinkForStatistics <> Undefined
			And Common.HasObjectAttribute("PriceIncludesVAT", LinkForStatistics.Metadata()) Then
			AttributesDetails1 = New Structure;
			Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
			If Common.HasObjectAttribute("Author", LinkForStatistics.Metadata()) Then
				Parameters.StatisticsCollectionSections.UseAlways = "Author";
				Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
			EndIf;
			ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "PriceIncludesVAT", Parameters);
			DetailsToFillIn = ObjectsFillingByStatistics.GetBankingDetailsValues(LinkForStatistics, AttributesDetails1);
			PriceIncludesVAT = DetailsToFillIn.PriceIncludesVAT;
		EndIf;
		
		AttributesStructure1.Insert("PriceIncludesVAT", PriceIncludesVAT);
		
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// Specifies the details of the selected price type.
//
// Parameters:
//	PriceKind - CatalogRef.TypesOfPrices - Link to the price view
//
// Returns:
//	Structure - details of the selected type of price.
//
Function GetPriceTypeDetails(PriceKind) Export
	
	Query = New Query("SELECT ALLOWED
	|	TypesOfPrices.PriceCurrency AS PriceCurrency,
	|	TypesOfPrices.PriceIncludesVAT AS PriceIncludesVAT
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Ref = &PriceKind");
	
	Query.SetParameter("PriceKind", PriceKind);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		PriceCurrency = Selection.PriceCurrency;
		PriceIncludesVAT = Selection.PriceIncludesVAT;
	Else
		PriceCurrency = Catalogs.Currencies.EmptyRef();
		PriceIncludesVAT = False;
	EndIf;
	
	AttributesStructure1 = New Structure("PriceCurrency, PriceIncludesVAT",
		PriceCurrency,
		PriceIncludesVAT);
	
	Return AttributesStructure1;

EndFunction

// Performs the formation of a new SKD.
//
// Returns:
//  DataCompositionSchema - the circuit layout data.
//
Function CreateNewDataLayoutScheme() Export
	
	QueryText = 
		"SELECT
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	&UseItemVariants AS Characteristic,
		|	&UseItemPackages AS Package,
		|	0 AS Price,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency
		|{SELECT
		|	Products.*,
		|	Characteristic.*,
		|	Package.*,
		|	Price,
		|	Currency.*}
		|";
		
	If GetFunctionalOption("UseItemVariants") Then
		
		QueryText = StrReplace(QueryText, "&UseItemVariants", 
								"VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
		
	Else
		
		QueryText = StrReplace(QueryText, "&UseItemVariants AS Characteristic,", "");
		QueryText = StrReplace(QueryText, "Characteristic.*,", "");
		
	EndIf;
	
	If GetFunctionalOption("UseItemPackages") Then
		
		QueryText = StrReplace(QueryText, "&UseItemPackages AS Package,", 
								"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
								|	1 AS ZoomRatio,");
		QueryText = StrReplace(QueryText, "Package.*,", "Package.*,
																|	ZoomRatio,");
		
	Else
		
		QueryText = StrReplace(QueryText, "&UseItemPackages AS Package,", "");
		QueryText = StrReplace(QueryText, "Package.*,", "");
		
	EndIf;
	
	DCS                         = New DataCompositionSchema;
	Source                    = DCS.DataSources.Add();
	Source.Name                = "DataSourceProductPrices";
	Source.DataSourceType = "Local";
	DataSet                 = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name             = "ItemsPrices";
	DataSet.Query          = QueryText;
	DataSet.DataSource = "DataSourceProductPrices";
	DataSet.AutoFillAvailableFields = False;
	
	RequiredFields = PriceManagementSystem.GetRequiredDataLayoutSchemaFields();
	
	For Each RequiredField In RequiredFields Do
		
		NewField             = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		NewField.Field        = RequiredField.Key;
		NewField.DataPath = RequiredField.Key;
		NewField.ValueType = RequiredField.Value;
		
	EndDo;
	
	Return DCS;

EndFunction

// Initializes the parameter structure to get a description and layout diagrams of the data by the layout name
//
// Returns:
//  Structure - structure with properties:
//   * Ref - CatalogRef.TypesOfPrices - Type of price.
//   * TemplateName - String, Undefined - name of the layout.
//   * GetSettings - Boolean - True - get the settings again, False-use the transmitted data.
//   * StorageOfDataCompositionSchema - ValueStorage, Undefined - String pointer to the data layout schema storage.
//   * StorageOfDataCompositionSettings - ValueStorage, Undefined - String pointer to the storage of data layout settings.
//   * StorageOfFilterByItemsDataCompositionSettings - ValueStorage, Undefined - String pointer to the storage 
//     of layout settings for item selection data.
//   * UsePriceManagementSystem25 - Boolean - flag for using the new pricing.
//
Function InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName() Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Catalogs.TypesOfPrices.EmptyRef());
	Parameters.Insert("TemplateName", Undefined);
	Parameters.Insert("GetSettings", True);
	Parameters.Insert("StorageOfDataCompositionSchema", Undefined);
	Parameters.Insert("StorageOfDataCompositionSettings", Undefined);
	Parameters.Insert("StorageOfFilterByItemsDataCompositionSettings", Undefined);
	Parameters.Insert("UsePriceManagementSystem25", False);
	
	Return Parameters;
	
EndFunction

// Returns a structure with a synonym and
// a data layout scheme by the layout name.
//
// Parameters:
//	TemplateParameters1 - See InitializeParmeterStructureToGetDescriptionOfLayoutSchemesByName.
//	RereadDiagram - Boolean - True - read the schema from the reference book, False-use the cache.
//
// Returns:
//  Structure - structure with properties:
//   * LongDesc - String - Description of the line-up scheme.
//   * DataCompositionSchema - DataCompositionSchema, Undefined - the circuit layout data.
//   * DataCompositionSettings - Undefined - Customize the layout of the data.
//   * ProductSelectionDataLayoutSettings - Undefined - Settings for the layout of selection data by item.
//   * LayoutSettingsForRefinementData - Undefined - Settings for the layout of selection data by default.
//
Function GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1, RereadDiagram = False) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("LongDesc",                  						"");
	ReturnValue.Insert("DataCompositionSchema",     						Undefined);
	ReturnValue.Insert("DataCompositionSettings", 						Undefined);
	ReturnValue.Insert("ProductSelectionDataLayoutSettings", 	Undefined);
	ReturnValue.Insert("LayoutSettingsForRefinementData", 			Undefined);
	
	If TemplateParameters1.GetSettings Then
		
		If Not TemplateParameters1.Ref.IsEmpty() Then
			Query = New Query(
			"SELECT
			|	TypesOfPrices.StorageOfDataCompositionSchema AS StorageOfDataCompositionSchema,
			|	TypesOfPrices.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings,
			|	TypesOfPrices.StorageOfFilterByItemsDataCompositionSettings AS StorageOfFilterByItemsDataCompositionSettings
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|WHERE
			|	TypesOfPrices.Ref = &Ref
			|	AND NOT TypesOfPrices.IsFolder ");
			
			Query.SetParameter("Ref", TemplateParameters1.Ref);
			
			Result = Query.Execute();
			Selection = Result.Select();
		EndIf;
		
		If Not ValueIsFilled(TemplateParameters1.TemplateName) Then
			
			ReturnValue.LongDesc = TemplateParameters1.TemplateName;
			If Not TemplateParameters1.Ref.IsEmpty() And Selection.Next() Then
				StorageOfDataCompositionSchema = Selection.StorageOfDataCompositionSchema; // ValueStorage
				DataCompositionSchema = StorageOfDataCompositionSchema.Get();
				If DataCompositionSchema = Undefined Then
					ReturnValue.DataCompositionSchema = CreateNewDataLayoutScheme();
				Else
					ReturnValue.DataCompositionSchema = DataCompositionSchema;
					StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
					ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
					StorageOfFilterByItemsDataCompositionSettings = Selection.StorageOfFilterByItemsDataCompositionSettings; // ValueStorage
					ReturnValue.ProductSelectionDataLayoutSettings = StorageOfFilterByItemsDataCompositionSettings.Get();
					ReturnValue.LayoutSettingsForRefinementData = StorageOfDataCompositionSettings.Get();
					If ValueIsFilled(ReturnValue.ProductSelectionDataLayoutSettings) Then
						DataCompositionClientServer.CopyDataCompositionFilter(ReturnValue.DataCompositionSchema,ReturnValue.DataCompositionSettings, ReturnValue.ProductSelectionDataLayoutSettings);
					EndIf;
					
				EndIf;
			EndIf;
			
		Else
			
			GetDataLayoutDescriptionAndSchemaByFragmentTemplateName(TemplateParameters1, RereadDiagram, ReturnValue);	
	
			If Not TemplateParameters1.Ref.IsEmpty() And Selection.Next() Then
				StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
				StorageOfFilterByItemsDataCompositionSettings = Selection.StorageOfFilterByItemsDataCompositionSettings; // ValueStorage
				ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
				ReturnValue.ProductSelectionDataLayoutSettings = StorageOfFilterByItemsDataCompositionSettings.Get();
				ReturnValue.LayoutSettingsForRefinementData = StorageOfDataCompositionSettings.Get();
			EndIf;
			
		EndIf;
		
	Else
			
		If Not ValueIsFilled(TemplateParameters1.TemplateName) Then
			
			ReturnValue.LongDesc = TemplateParameters1.TemplateName;
				
			DataCompositionSchema = TemplateParameters1.StorageOfDataCompositionSchema.Get();
			If DataCompositionSchema = Undefined Then
				ReturnValue.DataCompositionSchema = CreateNewDataLayoutScheme();
			Else
				ReturnValue.DataCompositionSchema = DataCompositionSchema;
				ReturnValue.DataCompositionSettings = TemplateParameters1.StorageOfDataCompositionSettings.Get();
				ReturnValue.ProductSelectionDataLayoutSettings = TemplateParameters1.StorageOfFilterByItemsDataCompositionSettings.Get();
				ReturnValue.LayoutSettingsForRefinementData = TemplateParameters1.StorageOfDataCompositionSettings.Get();
			EndIf;
		
		Else
	
			GetDataLayoutDescriptionAndSchemaByFragmentTemplateName(TemplateParameters1, RereadDiagram, ReturnValue);	
	
			ReturnValue.DataCompositionSettings = TemplateParameters1.StorageOfDataCompositionSettings.Get();
			ReturnValue.ProductSelectionDataLayoutSettings = TemplateParameters1.StorageOfFilterByItemsDataCompositionSettings.Get();
			ReturnValue.LayoutSettingsForRefinementData = TemplateParameters1.StorageOfDataCompositionSettings.Get();
		EndIf;
			
	EndIf;
	
	ParameterCountryOfVATRates = DataCompositionClientServer.GetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates");
	If ParameterCountryOfVATRates <> Undefined And Not ValueIsFilled(ParameterCountryOfVATRates.Value) Then
		DataCompositionClientServer.SetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates", SettingsValueClientServerCached.MainCountry());
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Parameters:
// 	TemplateParameters1 - Structure
// 	RereadDiagram - Boolean
// 	ReturnValue - Structure
Procedure GetDataLayoutDescriptionAndSchemaByFragmentTemplateName(TemplateParameters1, Val RereadDiagram, ReturnValue)
	If RereadDiagram Then
		ReturnValue.LongDesc 				= Metadata.Catalogs.TypesOfPrices.Templates.Find(TemplateParameters1.TemplateName).Synonym;
		ReturnValue.DataCompositionSchema 	= Catalogs.TypesOfPrices.GetTemplate(TemplateParameters1.TemplateName);
		
		PriceManagementSystemServerCall.GetPricingScheme(ReturnValue.DataCompositionSchema);
		
		ParameterCountryOfVATRates = DataCompositionClientServer.GetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates");
		If ParameterCountryOfVATRates <> Undefined And Not ValueIsFilled(ParameterCountryOfVATRates.Value) Then
			DataCompositionClientServer.SetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates", SettingsValueClientServerCached.MainCountry());
		EndIf;
	Else
		FillPropertyValues(ReturnValue, SettingPricesCached.GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateParameters1.TemplateName, TemplateParameters1.UsePriceManagementSystem25));
	EndIf;
EndProcedure

// Returns an array of price types available to the user
//
// Returns:
//	Array - types of prices allowed to the user.
//
Function AvailableTypesOfPrices(Filters = Undefined) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	TypesOfPrices.Ref AS PriceKind
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TRUE
	|");
	
	If Filters <> Undefined Then
		For Each Filter In Filters Do
			Query.Text = Query.Text + Chars.LF + "	AND TypesOfPrices." + Filter.Key + " = &" + Filter.Key;
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
	EndIf;
	
	QueryResult = Query.Execute();
	Return QueryResult.Unload().UnloadColumn("PriceKind");
	
EndFunction

// Determines the price of output by default
//
// Returns:
//	CatalogRef.TypesOfPrices - the found type of prices.
//
Function TypeOfPricePlannedCostOfInventory(PriceKind = Undefined) Export
	
	If ValueIsFilled(PriceKind) Then
		Return PriceKind;
	EndIf;
	
	// selecting a single value of a price type or a value from a constant
	Result = DefaultPriceType(Constants.PriceKindOfPlannedCostOfMaterialsAndWorks.Get());
	
	// An attempt to choose a single type of price with a sign of using a special product.
	If Not ValueIsFilled(Result) Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 2 ALLOWED
		|	TypesOfPrices.Ref AS PriceKind
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	NOT TypesOfPrices.DeletionMark
		|	AND TypesOfPrices.UseForIssuingProductsWorksAndServicesAtFixedCost";
		
		Selection = Query.Execute().Select();
		
		If Selection.Count() = 1 And Selection.Next() Then
			Result = Selection.PriceKind;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Opionionated
// Parameters:
// PriceKind - CatalogRef.TypesOfPrices - the price that you want to install
// IsInstallation - Boolean - flag for setting / resetting the price type
// ItemsCollection - Array - type (reference Link, Warehouses) a collection of similar links that require setting the price type
// VariableValue - String - literal variants: "Retail", " Accounting"
Procedure SetTypeOfPriceInObjects(
	Val PriceKind,
	Val IsInstallation,
	Val ItemsCollection, 
	Val VariableValue) Export
	
	Var TypeOfInstallationObject,ChangeablePropsName,AddlCondition;
	
	TypeOfInstallationObject = TypeOf(ItemsCollection[0]);
	TableName = Common.TableNameByRef(ItemsCollection[0]);
	
	NamesOfPriceTypeDetails = New Array;
	NamesOfPriceTypeDetails.Add("Description");
	NamesOfPriceTypeDetails.Add("UseWhileSellingToCustomers");
	NamesOfPriceTypeDetails.Add("UseForWholesaleToCustomers");
	NamesOfPriceTypeDetails.Add("UseForRetailSalesToCustomers");
	NamesOfPriceTypeDetails.Add("Purpose");
	DetailsOfPriceType_ = Common.ObjectAttributesValues(PriceKind,StrConcat(NamesOfPriceTypeDetails,","));
	
	If Not DetailsOfPriceType_.Purpose = Enums.PriceTypesAssignment.Shared Then
		UserMessage = 
			NStr("vi = 'Không thể thiết lập/xóa dạng giá ""%1"" bởi vì đó là dạng giá riêng.';
				|ru = 'Вид цены ""%1"" недоступен для установки/очистки, поскольку является индивидуальным.';
				|en = 'Price type ""%1"" is not available for setting/cleaning since it is individual.'; fa = 'Price type ""%1"" is not available for setting/cleaning since it is individual.';
				|it = 'Tipo di prezzo ""%1"" non disponibile per l''installazione/pulizia, in quanto risulta individuale.';
				|pl = 'Rodzaj ceny ""%1"" jest niedostępny dla ustawienia/oczyszczenia, ponieważ jest indywidualnym.';
				|tr = 'Fiyat türü ""%1"", özelleştirilmiş olduğu için yapılandırma/temizleme için kullanılamaz.'");
		UserMessage = 
			StringFunctionsClientServer.SubstituteParametersToString(UserMessage,DetailsOfPriceType_.Description);
		CommonClientServer.MessageToUser(UserMessage);
		Return;
	EndIf; 
	
	If TypeOfInstallationObject = Type("CatalogRef.Warehouses") Then
		
		If VariableValue = "Retail_2" Then
			ChangeablePropsName = "RetailPriceType";
			AddlCondition = "
			|	TypesOfPrices.UseForRetailSalesToCustomers
			|			AND ObjectOfPriceTypeChange.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)";
		ElsIf VariableValue = "Accounting_0" Then
			ChangeablePropsName = "AccountingPriceType";
			AddlCondition = "
			|	True";
		EndIf;
		
		Common.TableNameByRef(ItemsCollection[0]);

	ElsIf TypeOfInstallationObject = Type("CatalogRef.StoreFormats") Then
		
		If VariableValue = "Retail_2" Then
			ChangeablePropsName = "RetailPriceType";
			AddlCondition = "TypesOfPrices.UseForRetailSalesToCustomers";
		Else
			UserMessage = 
				NStr("vi = 'Đối với đối tượng kiểu ""%1"" không có dạng giá khác với giá bán lẻ để đặt/xóa.';
					|ru = 'Для объектов типа ""%1"" недоступен для установки/очистки вид цен, отличный от розничного.';
					|en = 'The price type other than retail is not available for setting/cleaning for objects type ""%1"".'; fa = 'The price type other than retail is not available for setting/cleaning for objects type ""%1"".';
					|it = 'Per gli oggetti del tipo ""%1"" non è disponibile il tipo di prezzo diverso da quello al dettaglio per l''impostazione/cancellazione.';
					|pl = 'Dla obiektów typu ""%1"" niedostępny jest do ustawienia/oczyszczenia rodzaj cen, który różni się od detalicznego.';
					|tr = '""%1"" tipindeki nesneler için, perakende dışındaki fiyatların yapılandırılmasında/temizlenmesinde kullanılamaz.'");
			UserMessage = 
				StringFunctionsClientServer.SubstituteParametersToString(UserMessage,TypeOfInstallationObject);
			CommonClientServer.MessageToUser(UserMessage);
			Return;
		EndIf;
		
	ElsIf TypeOfInstallationObject = Type("CatalogRef.Partners") 
		  Or TypeOfInstallationObject = Type("CatalogRef.TermsOfSale") Then
		  
		If VariableValue = "Accounting_0" Then
			ChangeablePropsName = "PricesKind";
			AddlCondition = "TypesOfPrices.UseWhileSellingToCustomers";
		Else
			UserMessage = 
				NStr("vi = 'Đối với đối tượng kiểu ""%1"" không có dạng giá khác với giá kế toán để đặt/xóa.';
					|ru = 'Для объектов типа ""%1"" недоступен для установки/очистки вид цен, отличный от учетного.';
					|en = 'The price type other than accounting is not available for setting/cleaning for objects type ""%1"".'; fa = 'The price type other than accounting is not available for setting/cleaning for objects type ""%1"".';
					|it = 'Per gli oggetti di tipo ""%1"" non è disponibile il tipo di prezzo diverso da quello contabile per l''impostazione/cancellazione.';
					|pl = 'Dla obiektów typu ""%1"" niedostępny jest do ustawienia/oczyszczenia rodzaj cen, który różni się od ewidencyjnego.';
					|tr = '""%1"" tipindeki nesneler için, muhasebe dışındaki fiyatların yapılandırılmasında/temizlenmesinde kullanılamaz.'");
			UserMessage = 
				StringFunctionsClientServer.SubstituteParametersToString(UserMessage,TypeOfInstallationObject);
			CommonClientServer.MessageToUser(UserMessage);
			Return;
		EndIf;
		
	Else
		
		UserMessage = 
			NStr("vi = 'Đối tượng kiểu ""%1"" chưa xác định trình tự làm việc với các dạng giá';
				|ru = 'Для объектов типа ""%1"" не определен порядок работы с видами цен';
				|en = 'The procedure for working with price types is not defined for objects type ""%1""'; fa = 'The procedure for working with price types is not defined for objects type ""%1""';
				|it = 'Per gli oggetti di tipo ""%1"" non è determinato un ordine di lavoro con i tipi di prezzo';
				|pl = 'Dla obiektu typa ""%1"" nie określono trybu pracy z rodzajami cen';
				|tr = '""%1"" tipindeki nesneler için fiyat türleri ile çalışma düzeni tanımlanmamıştır'");
		UserMessage = 
			StringFunctionsClientServer.SubstituteParametersToString(UserMessage,TypeOfInstallationObject);
		CommonClientServer.MessageToUser(UserMessage);
		
	EndIf; 
	
	AdditionalRequestParameters = New Structure("TableName,NameOfPropsToChange,AddlCondition");
	AdditionalRequestParameters.Insert("TableName",TableName);
	AdditionalRequestParameters.Insert("NameOfPropsToChange",ChangeablePropsName);
	AdditionalRequestParameters.Insert("AddlCondition",AddlCondition);
	QueryText = RequestingDataToChange(AdditionalRequestParameters);
	
	Query = New Query(QueryText);
	Query.SetParameter("PriceKind",PriceKind);
	Query.SetParameter("ArrayOfObjectsToModify",ItemsCollection);
	
	Selection = Query.Execute().Select();
	CountUpdated = 0;
	CanTUpdate = New Array;
	RecordingErrors_ = New Array;
	
	While Selection.Next() Do
		
		ValueToSet = ?(IsInstallation,Selection.SetPriceType,Catalogs.TypesOfPrices.EmptyRef());
		
		If Selection.AddlCondition And Not Selection.ThisIsIndividualTypeOfPrice Then
			If ValueToSet = Selection.ValueOfPriceType Then
				CountUpdated = CountUpdated + 1;
			Else
				ChangeObject = Selection.Ref.GetObject();
				ChangeObject[ChangeablePropsName] = ValueToSet;
				Try
					ChangeObject.Write();
					CountUpdated = CountUpdated + 1;
				Except
					RecordingErrors_.Add(ErrorDescription());
				EndTry; 
			EndIf;
		Else
			CanTUpdate.Add(Selection.RefPresentation);
		EndIf; 
		
	EndDo; 
	
	If CanTUpdate.Count() > 0 Or RecordingErrors_.Count() > 0 Then
		UserMessage = NStr("vi = 'Đã cập nhật %1 phần tử';
							|ru = 'Обновлено %1 элементов';
							|en = 'Updated %1 items'; fa = 'Updated %1 items';
							|it = 'Aggiornato %1 elemento';
							|pl = 'Zaktualizowano %1 elementów';
							|tr = '%1 öğeleri güncellendi'");
		UserMessage = StringFunctionsClientServer.SubstituteParametersToString(UserMessage,CountUpdated);
		Common.MessageToUser(UserMessage);
		
		If CanTUpdate.Count() > 0 Then
			UserMessage = NStr("vi = 'Không thể thay đổi dạng giá ""%1"" đối với %2phần tử:
			|%3';
			|ru = 'Нельзя изменить вид цены ""%1"" для %2 элемента(-ов):
			|%3';
			|en = 'Cannot change price type ""%1"" for %2 item(s):
			|%3'; fa = 'Cannot change price type ""%1"" for %2 item(s):
			|%3';
			|it = 'Impossibile modificare il tipo di prezzo ""%1""per %2 elementi: 
			|%3';
			|pl = 'Nie można zmienić rodzaj ceny ""%1"" dla %2 elementu(-ów):
			|%3';
			|tr = '%2 öğesi(leri) için ""%1"" fiyat türü değiştirilemez:
			|%3'");
			UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
				UserMessage,Common.ObjectAttributeValue(PriceKind,"Description"),
				CanTUpdate.Count(),StrConcat(CanTUpdate,Chars.LF));
			Common.MessageToUser(UserMessage);
		EndIf; 
		
		If RecordingErrors_.Count() > 0 Then
			UserMessage = NStr("vi = 'lỗi khi cập nhật %1 phần tử:
			|%2';
			|ru = 'ошибки при обновлении %1 элементов:
			|%2';
			|en = 'errors when updating %1 elements:
			|%2'; fa = 'errors when updating %1 elements:
			|%2';
			|it = 'Errori durante l''aggiornamento %1 elementi:
			|%2';
			|pl = 'błędy podczas aktualizacji %1 elementów:
			|%2';
			|tr = '%1 öğeleri güncellenirken hatalar oluştu:
			|%2'");
			UserMessage = StringFunctionsClientServer.SubstituteParametersToString(
				UserMessage,RecordingErrors_.Count(),StrConcat(RecordingErrors_,Chars.LF));
			Common.MessageToUser(UserMessage);
		EndIf; 
	EndIf; 
	
EndProcedure

Function RequestingDataToChange(AdditionalRequestParameters)
	
	ManagerByName = Common.ObjectManagerByFullName(AdditionalRequestParameters.TableName);
	MetadataTables = ManagerByName.EmptyRef().Metadata();
	SubordinationToElements = MetadataTables.SubordinationUse = Metadata.ObjectProperties.SubordinationUse.ToItems;
	
	QueryText = 
	"SELECT
	|	TypesOfPrices.Ref AS SetPriceType,
	|	TypesOfPrices.Purpose <> VALUE(Enum.PriceTypesAssignment.Shared) AS ThisIsIndividualTypeOfPrice,
	|	ObjectOfPriceTypeChange.Ref AS Ref,
	|	&CurValueOfPriceType AS ValueOfPriceType,
	|	&AddlCondition AS AddlCondition,
	|	PRESENTATION(ObjectOfPriceTypeChange.Ref) AS RefPresentation
	|FROM
	|	&TableOfObjectBeingModified AS ObjectOfPriceTypeChange
	|		INNER JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON (TRUE)
	|WHERE
	|	TypesOfPrices.Ref = &PriceKind
	|	AND &SubordinationToElements
	|	AND ObjectOfPriceTypeChange.Ref IN(&ArrayOfObjectsToModify)
	|
	|ORDER BY
	|	Ref
	|AUTOORDER";
	
	QueryText = StrReplace(QueryText,"&TableOfObjectBeingModified",AdditionalRequestParameters.TableName);
	QueryText = StrReplace(QueryText,"&CurValueOfPriceType","ObjectOfPriceTypeChange." + AdditionalRequestParameters.NameOfPropsToChange);
	QueryText = StrReplace(QueryText,"&AddlCondition",AdditionalRequestParameters.AddlCondition);
	QueryText = StrReplace(QueryText,"AND &SubordinationToElements",?(SubordinationToElements,"","AND NOT ObjectOfPriceTypeChange.IsFolder"));
	
	
	Return QueryText;
	
EndFunction

// Returns permission to change the formula for the price type
// 
// Parameters:
// 	PricingMethod - EnumRef.PriceSettingMethods - Method for setting the calculation for which you need to get permission
// Returns:
// 	Boolean - Permission or prohibition to change the formula
Function AllowChangingFormulas(PricingMethod) Export
	
	If PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes
		Or PricingMethod = Enums.PriceSettingMethods.AnotherPriceTypeMarkup Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

// Returns the created price view
// 
// Parameters:
// 	CreationParameters - See InitializeParametersForCreatingPriceView
// Returns:
// 	Structure - See SettingPricesServer.InitializeResultStructure
Function CreateNewPriceView(CreationParameters) Export

	Cancel = False;
	
	CreationResult = SettingPricesServer.InitializeResultStructure();

	NewObject = Catalogs.TypesOfPrices.CreateItem();
	
	FillPropertyValues(NewObject, CreationParameters);
	NewObject.Id = TMCommonUseClientServer.GetID(NewObject.Description);
	
	If NewObject.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
		AvailableBasicPriceTypes = GetTableOfBasePrices(NewObject.Ref);
	EndIf;
		
	If CreationParameters.PriceGroups.Count() Then
		
		For Each String In CreationParameters.PriceGroups Do
			
			NewRow = NewObject.PriceGroups.Add();
			FillPropertyValues(NewRow, String);

			If NewObject.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
				
				ExtractBasePricesFromFormula(NewObject, AvailableBasicPriceTypes, String.Formula, Cancel);
				
				If Cancel Then
					
					CreationResult.Result = False;
					CreationResult.ErrorDescription = NStr("vi = 'Trong dạng giá, đã chỉ ra đơn giá ảnh hưởng không chính xác. Hãy kiểm tra công thức hoặc dạng giá cơ bản.';
															|ru = 'В виде цен указана некорректная влияющая цена. Проверьте формулы или вид цен основание.';
															|en = 'An incorrect influencing price is specified in the price type. Check the formulas or price type basis.'; fa = 'An incorrect influencing price is specified in the price type. Check the formulas or price type basis.';
															|it = 'В виде цен указана некорректная влияющая цена. Проверьте формулы или вид цен основание.';
															|pl = 'An incorrect influencing price is specified in the price type. Check the formulas or price type basis.';
															|tr = 'Fiyat türünde yanlış bir etkileyen fiyat belirtildi. Formülleri veya fiyat türünün temelini kontrol edin.'");
		
					Raise CreationResult.ErrorDescription;
					
				EndIf;

			EndIf;
			
		EndDo;
		
	EndIf;

	If NewObject.PricingMethod = Enums.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes Then
		
		ExtractBasePricesFromFormula(NewObject, AvailableBasicPriceTypes, NewObject.Formula, Cancel);
		
	EndIf;

	Try
		NewObject.Write();
		
		CreationResult.Insert("Ref", NewObject.Ref);
		
	Except
	
		CreationResult.Result = False;
		CreationResult.ErrorDescription = ErrorDescription();
		
		Raise CreationResult.ErrorDescription;
		
	EndTry;
	
	Return CreationResult;
	
EndFunction

// Extract the base prices from the formula.
// 
// Parameters:
//  Object - CatalogObject.TypesOfPrices - Object
//  AvailableBasicPriceTypes - ValueTable - Available basic types of prices
//  Formula - String - Formula
//  Cancel - Boolean - 
Procedure ExtractBasePricesFromFormula(Object, AvailableBasicPriceTypes, Formula, Cancel) Export
	
	ItemArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Formula, "[");
	
	For IndexOf = 1 To ItemArray.Count() - 1 Do
		
		If ValueIsFilled(ItemArray[IndexOf]) Then
			
			IDEnding = StrFind(ItemArray[IndexOf], "]");
			
			If IDEnding > 0 Then
				
				BasePriceID = Left(ItemArray[IndexOf], IDEnding - 1);
				BasePrices = AvailableBasicPriceTypes.FindRows(New Structure("Id", BasePriceID));
				
				If BasePrices.Count() > 0 Then
					
					If Object.InfluencingPriceTypes.FindRows(New Structure("InfluencingPriceType", BasePrices[0].Ref)).Count() = 0 Then
						Object.InfluencingPriceTypes.Add().InfluencingPriceType = BasePrices[0].Ref;
					EndIf;
				
				Else // Error
					
					Cancel = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Get a table of base prices.
// 
// Parameters:
//  CurPrice - CatalogRef.TypesOfPrices - Type of price
// 
// Returns:
//  ValueTable - Get A Table Of Base Prices
Function GetTableOfBasePrices(CurPrice) Export
	
	RequestPermittedTypesOfPrices = New Query(
	"SELECT ALLOWED
	|	TypesOfPrices.Ref
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)");
	
	Query = New Query(
		"SELECT
		|	TypesOfPrices.Ref          AS Ref,
		|	TypesOfPrices.Id   AS Id,
		|	TypesOfPrices.DeletionMark AS DeletionMark,
		|	CASE WHEN TypesOfPrices.Ref NOT IN (&PermittedTypesOfPrices) THEN TRUE ELSE FALSE END AS ProhibitedPriceType,
		|	TypesOfPrices.InfluencingPriceTypes.(
		|		InfluencingPriceType      AS InfluencingPriceType
		|	)
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Ref <> &CurPrice
		|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)");
			
	Query.SetParameter("CurPrice", CurPrice);
	Query.Parameters.Insert("PermittedTypesOfPrices", RequestPermittedTypesOfPrices.Execute().Unload().UnloadColumn("Ref"));
	
	SetPrivilegedMode(True);
	TableOfPriceTypes = Query.Execute().Unload();
	
	CurrentArray = New Array();
	CurrentArray.Add(CurPrice);
	
	While CurrentArray.Count() > 0 Do
		
		ArrayDeletition = New Array();//Array of ValueTableRow
		
		For Each TableRow In TableOfPriceTypes Do
			
			For Each PriceKind In CurrentArray Do
				
				If TableRow.InfluencingPriceTypes.Find(PriceKind, "InfluencingPriceType") <> Undefined Or TableRow.ProhibitedPriceType Then
					
					ArrayDeletition.Add(TableRow);
					Break;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		CurrentArray.Clear();
		
		For Each RowToDelete In ArrayDeletition Do
			
			CurrentArray.Add(RowToDelete.Ref);
			TableOfPriceTypes.Delete(RowToDelete);
			
		EndDo;
		
	EndDo;
	
	TableOfPriceTypes.Columns.Delete(TableOfPriceTypes.Columns.InfluencingPriceTypes);
	
	Return TableOfPriceTypes; 
EndFunction

// Initializes the parameter structure to create a new price type
//
// Returns:
//  Structure - structure with properties:
//  * Description - String - Name of the price type
//  * PricingMethod - EnumRef.PriceSettingMethods - Method for setting the price
//  * Status - EnumRef.StatusesOfPriceTypeValidity - Price type status
//  * PriceCurrency - CatalogRef.Currencies - Currency of the price type
//  * DataCompositionSchema - String - Name of the data layout scheme
//  * Purpose - EnumRef.PriceTypesAssignment - The purpose of the types of prices
//  * UseForRetailSalesToCustomers - Boolean - Flag for use in retail sales
//  * UseForWholesaleToCustomers - Boolean - Flag for use in wholesale sales
//  * UseForIssuingProductsWorksAndServicesAtFixedCost - Boolean - Indication of use in production
//  * UseForIntercompanySales - Boolean - Flag for use when transferring between organizations
//  * UseWhileTransferringProductsToMaterialProvider - Boolean - Flag for use when transmitting to the giver
//  * OptionForSpecifyingVATRates - EnumRef.OptionsForSpecifyingVATRatesInPriceList - option to specify the VAT rate in the price list
//  * Markup - Number - Mark-up amount
//  * Formula - String - Price type formula
//  * PriceGroups - ValueTable - Table by price groups with columns:
//    ** PriceGroup - CatalogRef.PriceGroups - Price group
//    ** Formula - String - Price type formula
//    ** BasicPriceType - CatalogRef.TypesOfPrices - Basic price type
//    ** Markup - Number - Mark-up amount
//
Function InitializeParametersForCreatingPriceView() Export

	Parameters = New Structure();
	Parameters.Insert("Description", "");
	Parameters.Insert("PricingMethod", Enums.PriceSettingMethods.Manually);
	Parameters.Insert("Status", Enums.StatusesOfPriceTypeValidity.Valid);
	Parameters.Insert("PriceCurrency", IncomeAndExpensesServer.GetCurrencyOfManagementAccounting());
	Parameters.Insert("PriceIncludesVAT", False);
	Parameters.Insert("DataCompositionSchema", "Typical");
	Parameters.Insert("Purpose", Enums.PriceTypesAssignment.Shared);
	Parameters.Insert("UseWhileSellingToCustomers", False);
	Parameters.Insert("UseForRetailSalesToCustomers", False);
	Parameters.Insert("UseForWholesaleToCustomers", False);
	Parameters.Insert("UseForIssuingProductsWorksAndServicesAtFixedCost", False);
	Parameters.Insert("UseForIntercompanySales", False);
	Parameters.Insert("UseWhileTransferringProductsToMaterialProvider", False);
	Parameters.Insert("Markup", 0);
	Parameters.Insert("Formula", "");
	Parameters.Insert("PercentRateOfManualDiscount", 0);
	Parameters.Insert("MaximumPercentageForManualMarkup", 0);
	Parameters.Insert("OptionForSpecifyingVATRates", Enums.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates);
	
	TablePriceGroups = New ValueTable();
	TablePriceGroups.Columns.Add("PriceGroup", New TypeDescription("CatalogRef.PriceGroups"));
	TablePriceGroups.Columns.Add("Formula", New TypeDescription("String"));
	TablePriceGroups.Columns.Add("BasicPriceType", New TypeDescription("CatalogRef.TypesOfPrices"));
	TablePriceGroups.Columns.Add("Markup", New TypeDescription("Number", New NumberQualifiers(10, 2)));
	
	Parameters.Insert("PriceGroups", TablePriceGroups);
	
	Return Parameters;
	
EndFunction

// Returns the created price view
// 
// Parameters:
// 	PriceKind - CatalogRef.TypesOfPrices - Disabled price view
// Returns:
// 	See SettingPricesServer.InitializeResultStructure
Function DisableIndividualPriceView(PriceKind) Export
	
	ShutdownResult = SettingPricesServer.InitializeResultStructure();
	
	If PriceKind.IsEmpty() Then
		ShutdownResult.Result = False;
		ShutdownResult.ErrorDescription = NStr("vi = 'Đã chuyển dạng giá trống.';
												|ru = 'Передан пустой вид цен.';
												|en = 'Blank price type passed.'; fa = 'Blank price type passed.';
												|it = 'Il tipo di prezzo passato è vuoto.';
												|pl = 'Przekazano pusty rodzaj cen.';
												|tr = 'Boş fiyat türü girildi.'");
	EndIf;
	
	ItemPriceType = PriceKind.GetObject();
	
	Try
		
		ItemPriceType.SetDeletionMark(True);
		
	Except
		
		ShutdownResult.Result = False;
		ShutdownResult.ErrorDescription = ErrorDescription();
		
	EndTry;
		
	Return ShutdownResult;
	
EndFunction

// Find an individual kind of pricing server.
// 
// Parameters:
//  IPLOwner Owner of the IPL
// 
// Returns:
//  See SettingPricesServer.InitializeResultStructure
Function FindIndividualViewOfPrices(IPLOwner) Export
	
	SearchResult = SettingPricesServer.InitializeResultStructure();

	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Description");
	ObjectAttributes = Common.ObjectAttributesValues(IPLOwner, AttributesStructure1);//Structure
	
	Query = New Query; 
	Query.Text = 
	"SELECT ALLOWED
	|	TypesOfPrices.Ref
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|		LEFT JOIN Catalog.TermsOfSale AS IPLOwner
	|		ON TypesOfPrices.Ref = IPLOwner.SpecialPriceType
	|WHERE
	|	TypesOfPrices.DeletionMark
	|	AND TypesOfPrices.Purpose = VALUE(Enum.PriceTypesAssignment.SpecialForTermsOfSales)
	|	AND TypesOfPrices.Description = &Description
	|	AND (IPLOwner.Ref = &Terms
	|	OR IPLOwner.Ref IS NULL)";
	
	Query.SetParameter("Terms", IPLOwner);
	Query.SetParameter("Description", ObjectAttributes.Description);
	
	If TypeOf(IPLOwner) = Type("CatalogRef.Warehouses") Then
		Query.Text =StrReplace(Query.Text, "Catalog.TermsOfSale", "Catalog.Warehouses");
		Query.Text =StrReplace(Query.Text, "SpecialForTermsOfSales", "SpecialForWarehouse");
	ElsIf TypeOf(IPLOwner) = Type("CatalogRef.StoreFormats") Then 
		Query.Text = StrReplace(Query.Text, "Catalog.TermsOfSale", "Catalog.StoreFormats");
		Query.Text =StrReplace(Query.Text, "SpecialForTermsOfSales", "SpecialForStoreFormat");
	ElsIf TypeOf(IPLOwner) = Type("CatalogRef.Partners") Then 
		Query.Text = StrReplace(Query.Text, "Catalog.TermsOfSale", "Catalog.Partners");
		Query.Text =StrReplace(Query.Text, "SpecialForTermsOfSales", "SpecialForPartner");
	EndIf;
	
	TableOfPriceTypes = Query.Execute().Unload();
	
	If TableOfPriceTypes.Count() Then
		
		PriceKind = TableOfPriceTypes[0].Ref;
		
		ItemPriceType = PriceKind.GetObject();
		
		Try
			
			ItemPriceType.SetDeletionMark(False);
			
		Except
			
			SearchResult.Result = False;
			SearchResult.ErrorDescription = ErrorDescription();
			
			Return SearchResult;
			
		EndTry;
		
		SearchResult.Ref = PriceKind;
	
	Else
	
		SearchResult.Result = False;
		SearchResult.ErrorDescription = "Kind prices_ not found. Necessary create new";
			
	EndIf;
			
	Return SearchResult;
	
EndFunction

// Find the price type ID.
// 
// Parameters:
//  IdentifiersOfBasicTypeOfPrices - Map - Identifiers Of The Basic Type Of Prices
//  PriceKind - CatalogRef.TypesOfPrices - Type of price
// 
// Returns:
//  Arbitrary - Find The Price Type Id
Function FindPriceTypeId(IdentifiersOfBasicTypeOfPrices, PriceKind) Export
	
	IdOfBasePriceType = IdentifiersOfBasicTypeOfPrices.Get(PriceKind);
	
	If IdOfBasePriceType = Undefined Then
		IdOfBasePriceType = Common.ObjectAttributeValue(PriceKind, "Id");
		IdentifiersOfBasicTypeOfPrices.Insert(PriceKind, IdOfBasePriceType);
	EndIf;
	
	Return IdOfBasePriceType;
	
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
	"AllowReadUpdate
	|WHERE
	|	IsFolder OR
	|	ValueAllowed(Ref)";
	
	Restriction.TextForExternalUsers1 =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)
	|	AND UseWhileSellingToCustomers";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// Parameters of the update handler
// 
// Parameters:
// 	Handlers - See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.TypesOfPrices.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.33";
	Handler.ExecutionMode = "Deferred";
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.TypesOfPrices.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler["Id"] = New UUID("ec2835ce-ddd2-44a6-946d-4fb6b8830d04");
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dạng giá"":';
								|ru = 'Обновление справочника ""Виды цен"":';
								|en = 'Update the ""Price types"" catalog:'; fa = 'Update the ""Price types"" catalog:';
								|it = 'Update the ""Price types"" catalog:';
								|pl = 'Update the ""Price types"" catalog:';
								|tr = '""Fiyat türleri"" kataloğunun güncellenmesi:'"));
	
	AttributesDetails1 = StrTemplate(NStr("vi = '- khi điền mục tin ""Tùy chọn chỉ ra thuế suất GTGT; "", ""Thuế suất GTGT; "", ""Quốc gia"".';
											|ru = '- при заполнении реквизитов ""Вариант указания ставок НДС; "", ""Ставка НДС; "", ""Страна"".';
											|en = '- when filling in the ""Option for specifying VAT rates"", ""VAT rate"", and ""Country"" attributes.'; fa = '- when filling in the ""Option for specifying VAT rates"", ""VAT rate"", and ""Country"" attributes.';
											|it = '- when filling in the ""Option for specifying VAT rates"", ""VAT rate"", and ""Country"" attributes.';
											|pl = '- when filling in the ""Option for specifying VAT rates"", ""VAT rate"", and ""Country"" attributes.';
											|tr = '- ""KDV oranı belirtme seçeneği"" öznitelikleri doldurulurken; ""KDV oranı"", ""Ülke"".'"));
	ListOfDescriptions.Add(AttributesDetails1);
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.TypesOfPrices.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.TypesOfPrices.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.TypesOfPrices.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Fetching data for the update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	Query = New Query;
	Query.Text = 
	"SELECT
	|	TypesOfPrices.Ref AS Ref
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT TypesOfPrices.IsFolder
	|	AND TypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.EmptyRef)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dạng mặt hàng"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Виды цен"" по обработчику:';
								|en = 'Cannot process the ""Price types"" catalog by the handler:'; fa = 'Cannot process the ""Price types"" catalog by the handler:';
								|it = 'Cannot process the ""Price types"" catalog by the handler:';
								|pl = 'Cannot process the ""Price types"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Fiyat türleri"" kataloğu işlenemedi:'"));
	
	AttributesDetails1 = StrTemplate(NStr("vi = '- khi điền mục tin %1';
											|ru = '- при заполнении реквизитов %1';
											|en = '- when filling in the %1 attributes'; fa = '- when filling in the %1 attributes';
											|it = '- when filling in the %1 attributes';
											|pl = '- when filling in the %1 attributes';
											|tr = '- %1 öznitelikleri doldurulurken'"), "OptionForSpecifyingVATRates; VATRate; Country.");
	ListOfDescriptions.Add(AttributesDetails1);
	
	MainCountry = VATAccountingLocalization.GetMainCountry();
	
	RefSet = UpdatedData.UnloadColumn("Ref");
	For Each ObjectReference In RefSet Do
	
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", ObjectReference.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				ObjectReference.Ref, ObjectReference.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			If CatalogObject <> Undefined Then
				
				CatalogObject.OptionForSpecifyingVATRates = Enums.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates;
				CatalogObject.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
				
				If ValueIsFilled(MainCountry) Then
					CatalogObject.Country = MainCountry;
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = "Record";
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(ObjectReference.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), ObjectReference.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					ObjectReference.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Var ParameterValue;
	Var TypeOfPriceType;
	Var OwnerOfAnIndividualPriceType;
	Var ToUseTermsOfSales;
	
	If Parameters.Property("OutputAnArbitraryTypeOfPrices", ParameterValue) And ParameterValue = True Then

		StandardProcessing = False;
		
		ChoiceData = New ValueList;
	
		UsePriceManagementSystem25 = False;
		If Not Parameters.Property("UsePriceManagementSystem25", UsePriceManagementSystem25) Then
			UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
		EndIf;
		
		If UsePriceManagementSystem25 And Parameters.Property("ToUseTermsOfSales", ToUseTermsOfSales) Then
			If ToUseTermsOfSales Then
				OwnerOfAnIndividualPriceType = ?(Parameters.Property("Terms"), Parameters.Terms, Undefined);
			Else
				OwnerOfAnIndividualPriceType = ?(Parameters.Property("Partner"), Parameters.Partner, Undefined);
			EndIf;
		EndIf;
		
		If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
			Query = New Query(
			"SELECT ALLOWED
			|	TypesOfPrices.Ref AS PricesKind,
			|	ISNULL(DataOnOwnerOfIndividualTypeOfPrices.Ref, &OwnerOfAnIndividualPriceType) AS OwnerOfAnIndividualPriceType
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|		LEFT JOIN &CatalogOfOwnerOfIndividualTypeOfPrices AS DataOnOwnerOfIndividualTypeOfPrices
			|		ON DataOnOwnerOfIndividualTypeOfPrices.SpecialPriceType = TypesOfPrices.Ref
			|WHERE
			|	TypesOfPrices.DeletionMark = FALSE
			|	AND TypesOfPrices.Description LIKE &SearchString
			|	AND &AdditionalConditions");
			
			If ToUseTermsOfSales Then
				CatalogOfOwnerOfIndividualTypeOfPrices = "Catalog.TermsOfSale";
			Else
				CatalogOfOwnerOfIndividualTypeOfPrices = "Catalog.Partners";
			EndIf;

			Query.Text = StrReplace(Query.Text, "&CatalogOfOwnerOfIndividualTypeOfPrices", CatalogOfOwnerOfIndividualTypeOfPrices);
			
		Else
			Query = New Query(
			"SELECT ALLOWED
			|	TypesOfPrices.Ref AS PricesKind
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|WHERE
			|	TypesOfPrices.DeletionMark = FALSE
			|	AND TypesOfPrices.Description LIKE &SearchString ESCAPE ""~""
			|	AND &AdditionalConditions");
		EndIf;
		
		SearchString = ?(Parameters.SearchString = Undefined, "", Parameters.SearchString);
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
		
		AdditionalConditions = New Array();
		
		// If the selection is passed in the parameters according to the requisites "Price includes"
		If Parameters.Filter.Property("PriceIncludesVAT") Then
			AdditionalConditions.Add("TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT");
			Query.SetParameter("PriceIncludesVAT", Parameters.Filter.PriceIncludesVAT);
		EndIf;
		// If the selection is passed in the parameters according to the requisites "Use the transfer between organizations".
		If Parameters.Filter.Property("UseForIntercompanySales") Then
			AdditionalConditions.Add("TypesOfPrices.UseForIntercompanySales = &UseForIntercompanySales");
			Query.SetParameter("UseForIntercompanySales", Parameters.Filter.UseForIntercompanySales);
		EndIf;
		// If the selection is passed in the parameters according to the "Use for Sale" props
		If Parameters.Filter.Property("UseWhileSellingToCustomers") Then
			AdditionalConditions.Add("TypesOfPrices.UseWhileSellingToCustomers = &UseWhileSellingToCustomers");
			Query.SetParameter("UseWhileSellingToCustomers", Parameters.Filter.UseWhileSellingToCustomers);
		EndIf;
		// If the selection is passed in the parameters according to the "Use for Wholesale Sale" props
		If Parameters.Filter.Property("UseForWholesaleToCustomers") Then
			AdditionalConditions.Add("TypesOfPrices.UseForWholesaleToCustomers = &UseForWholesaleToCustomers");
			Query.SetParameter("UseForWholesaleToCustomers", Parameters.Filter.UseForWholesaleToCustomers);
		EndIf;
		// If the selection is passed in the parameters according to the "Use for Retail Sale" props
		If Parameters.Filter.Property("UseForRetailSalesToCustomers") Then
			AdditionalConditions.Add("TypesOfPrices.UseForRetailSalesToCustomers = &UseForRetailSalesToCustomers");
			Query.SetParameter("UseForRetailSalesToCustomers", Parameters.Filter.UseForRetailSalesToCustomers);
		EndIf;
		// If the selection is passed in the parameters according to the "Status" details
		If Parameters.Filter.Property("Status") Then
			AdditionalConditions.Add("TypesOfPrices.Status = &Status");
			Query.SetParameter("Status", Parameters.Filter.Status);
		EndIf;
		
		// If the selection is passed in the parameters according to the "Auxiliary Price" props
		If Parameters.Filter.Property("AuxiliaryPrice") Then
			AuxiliaryPrice = Parameters.Filter.AuxiliaryPrice;
		Else
			AuxiliaryPrice = False;
		EndIf;
		AdditionalConditions.Add("TypesOfPrices.AuxiliaryPrice = &AuxiliaryPrice");
		Query.SetParameter("AuxiliaryPrice", AuxiliaryPrice);

		// If the parameters passed the selection according to the Attribute "useprivyproduction"
		If Parameters.Filter.Property("UseForIssuingProductsWorksAndServicesAtFixedCost") Then
			AdditionalConditions.Add("TypesOfPrices.UseForIssuingProductsWorksAndServicesAtFixedCost = &UseForIssuingProductsWorksAndServicesAtFixedCost");
			Query.SetParameter("UseForIssuingProductsWorksAndServicesAtFixedCost", Parameters.Filter.UseForIssuingProductsWorksAndServicesAtFixedCost);
		EndIf;
		// If the selection is passed in the parameters according to the props "Use the transfer of the product to the customer".
		If Parameters.Filter.Property("UseWhileTransferringProductsToMaterialProvider") Then
			AdditionalConditions.Add("TypesOfPrices.UseWhileTransferringProductsToMaterialProvider = &UseWhileTransferringProductsToMaterialProvider");
			Query.SetParameter("UseWhileTransferringProductsToMaterialProvider", Parameters.Filter.UseWhileTransferringProductsToMaterialProvider);
		EndIf;
		If ValueIsFilled(OwnerOfAnIndividualPriceType) Then
			AdditionalConditions.Add("ISNULL(DataOnOwnerOfIndividualTypeOfPrices.Ref, &OwnerOfAnIndividualPriceType) = &OwnerOfAnIndividualPriceType");
			Query.SetParameter("OwnerOfAnIndividualPriceType", OwnerOfAnIndividualPriceType);
		Else
			If Parameters.Filter.Property("Purpose") Then
				TypeOfPriceType = Parameters.Filter.Purpose;
			Else
				TypeOfPriceType = Enums.PriceTypesAssignment.Shared;
			EndIf;
			// If the selection is passed in the parameters according to the "Assignment" details
			AdditionalConditions.Add("TypesOfPrices.Purpose = &Purpose");
			Query.SetParameter("Purpose", TypeOfPriceType);
		EndIf;
		
		If Parameters.Property("TypesOfPrices", ParameterValue) And ParameterValue.Count() Then
			AdditionalConditions.Add("TypesOfPrices.Ref IN (&TypesOfPrices)");
			Query.SetParameter("TypesOfPrices", ParameterValue);
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&AdditionalConditions", StrConcat(AdditionalConditions, " And " + Chars.LF));
		
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("PricesKind"));
		
		ChoiceData.Add(Catalogs.TypesOfPrices.EmptyRef(), NStr("vi = '<tùy ý>';
																|ru = '<произвольная>';
																|en = '<custom>'; fa = '<سفارشی>';
																|it = '<arbitraria>';
																|pl = '<custom>';
																|tr = '<isteğe bağlı>'"));
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" And Not GetFunctionalOption("UseSeveralPriceTypes") Then
		
		Parameters.Insert("Key", PriceManagementSystemServerCall.PriceTypePriceList_());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf