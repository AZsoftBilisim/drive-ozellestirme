#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	GenerateWorkName =		Not (AdditionalProperties.Property("WorkingNameFormed"));
	GeneratePrintName =		Not (AdditionalProperties.Property("PrintNameGenerated"));
	
	SetPricingDetails = False;
	If Not AdditionalProperties.Property("UsePriceManagementSystem25", SetPricingDetails) Then
		SetPricingDetails = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	If TypeOf(Owner) = Type("CatalogRef.ItemKinds") Then
		ProductKind = Owner;
	Else
		ProductKind = Common.ObjectAttributeValue(Owner, "ProductKind");
	EndIf;
	
	If GenerateWorkName 
		Or GeneratePrintName
		Or SetPricingDetails Then

		AttributesStructure1 = New Structure;

		AttributesStructure1.Insert("WorkingNameTemplateCharacteristics");
		AttributesStructure1.Insert("ProhibitEditingWorkingTitleOfItemVariants");
		AttributesStructure1.Insert("NameTemplateForPrintingCharacteristics");
		AttributesStructure1.Insert("DisableNameChangeToPrintItemVariant");
		AttributesStructure1.Insert("SettingsOfPriceKeyByItemVariant");
		
		ObjectAttributes = Common.ObjectAttributesValues(ProductKind, AttributesStructure1);

		If GenerateWorkName
				And ValueIsFilled(ObjectAttributes.WorkingNameTemplateCharacteristics)
				And (ObjectAttributes.ProhibitEditingWorkingTitleOfItemVariants
				Or Not ValueIsFilled(Description)) Then
			DescriptionTemplate = ObjectAttributes.WorkingNameTemplateCharacteristics;
			Description = ProductsServer.NameByTemplate(DescriptionTemplate, ThisObject);
		EndIf;
		
		If GeneratePrintName
			And ValueIsFilled(ObjectAttributes.NameTemplateForPrintingCharacteristics) 
			And (ObjectAttributes.DisableNameChangeToPrintItemVariant 
			Or Not ValueIsFilled(DescriptionFull)) Then
			NameTemplateForPrinting = ObjectAttributes.NameTemplateForPrintingCharacteristics;
			DescriptionFull = ProductsServer.NameByTemplate(NameTemplateForPrinting, ThisObject);
		EndIf;
		
		PriceKeySettings = ObjectAttributes.SettingsOfPriceKeyByItemVariant;
		If SetPricingDetails 
			And ValueIsFilled(PriceKeySettings)
			And PriceKeySettings <> Enums.FilterOptionForPriceKey.DontUse Then
			
			SearchDetails_ = GetAttributesForSearch(ProductKind, ObjectAttributes);
			ItemsCharacteristicForPricing = GetCharacteristicsOfProductsForPricing(SearchDetails_);
			
			If ValueIsFilled(ItemsCharacteristicForPricing)
				And Not IsNew() Then

				PreviousValues1 = Common.ObjectAttributesValues(Ref, "DeletionMark"); 
				
				If DeletionMark <> PreviousValues1.DeletionMark Then
					
					SynchronizationParameters = New Structure();
					SynchronizationParameters.Insert("DeletionMark", DeletionMark);
					SynchronizationParameters.Insert("ProductCharacteristic", Ref);
					SynchronizationParameters.Insert("ItemsCharacteristicForPricing", ItemsCharacteristicForPricing);
					
					Catalogs.ItemsCharacteristicsForPricing.SyncDeleteTag(SynchronizationParameters);
					
				EndIf;
	
			EndIf;
			
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Description) Then
		ExceptionText = NStr("vi = 'Chưa điền trường ""Tên gọi làm việc""';
							|ru = 'Поле ""Рабочее наименование"" не заполнено';
							|en = '""Working title"" is required'; fa = '""Working title"" is required';
							|it = 'Il campo ""Titolo lavorativo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Nazwa robocza""';
							|tr = '""Çalışma tanımı"" alanı doldurulmadı'");
		Raise ExceptionText; 
	EndIf;
	
	MonitorWorkingName =
		Constants.ControlUniquenessOfWorkingNamesOfProductsAndItemVariants.Get()
		And Not (AdditionalProperties.Property("WorkingNameVerified"));
	
	If MonitorWorkingName
		And Not Cancel Then
		If Not Catalogs.ItemsCharacteristics.WorkingNameIsUnique(ThisObject) Then
			ExceptionText = NStr("vi = 'Giá trị trường ""Tên gọi làm việc"" không đơn trị';
								|ru = 'Значение поля ""Рабочее наименование"" не уникально';
								|en = 'Value of field ""Working title"" is not unique'; fa = 'Value of field ""Working title"" is not unique';
								|it = 'Il valore del campo ""Titolo lavorativo"" non è unico';
								|pl = 'Wartość pola ""Nazwa robocza"" nie jest unikalna';
								|tr = '""Çalışma tanımı"" alanının değeri benzersiz değil'");
			Raise ExceptionText; 
		EndIf;
	EndIf;
	
	If ValueIsFilled(Principal)
		And TypeOf(Principal) = Type("CatalogRef.Companies") Then
		Counterparty = Principal;
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());

EndProcedure // Before recording()

Procedure OnCopy(CopiedObject)
	ItemsCharacteristicForPricing = Catalogs.ItemsCharacteristicsForPricing.EmptyRef();
EndProcedure

Procedure OnWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure // Before removal()

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = Catalogs.ItemsCharacteristics.AttributesNotToCheck(ThisObject);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductsLocalization.ProcessingVerificationOfFillingInProductCharacteristics(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

// Get Attributes for the search.
// 
// Parameters:
//  ProductKind - CatalogRef.ItemKinds - Product kind
//  ObjectAttributes - Structure - details of the object
//  SearchForXCO - Boolean - Search for XCO
// 
// Returns:
//  Structure - Get Attributes For The Search:
// * CurrentCharacteristic - CatalogRef.ItemsCharacteristics -
// * CurCurrentCharacteristicsOfTSO - CatalogRef.ItemsCharacteristicsForPricing -
// * SearchForXCO - Boolean -
// * ProductKind - CatalogRef.ItemKinds -
// * OneToOneLink - Boolean - True, based on the characteristic of only one pricing characteristic
// * DetailsForPriceKey - ValueTable -
Function GetAttributesForSearch(Val ProductKind, Val ObjectAttributes, Val SearchForXCO = True) Export

	// get a list of additional details by which to search for har-ku
	DetailsForPriceKey = Catalogs.ItemKinds.GetDetailsForPricingKey(ProductKind, "Characteristics");

	SearchDetails_ = New Structure;
	SearchDetails_.Insert("CurrentCharacteristic",      Ref);
	SearchDetails_.Insert("CurCurrentCharacteristicsOfTSO",    ItemsCharacteristicForPricing);
	SearchDetails_.Insert("SearchForXCO",         SearchForXCO);
	SearchDetails_.Insert("ProductKind",            ProductKind);
	SearchDetails_.Insert("OneToOneLink",          False);

	If ObjectAttributes.SettingsOfPriceKeyByItemVariant = Enums.FilterOptionForPriceKey.UseByAttributes Then
		AdditionalAttributesData = AdditionalAttributes.Unload(); 

		For Each StringOfPropsForPriceKey In DetailsForPriceKey Do
			If StringOfPropsForPriceKey.IsAddlAttribute Then
				FoundRow = AdditionalAttributesData.Find(StringOfPropsForPriceKey.Property, "Property");
				If FoundRow = Undefined Then
					TypeDetails = New TypeDescription(StringOfPropsForPriceKey.Property.ValueType);
					StringOfPropsForPriceKey.Value = TypeDetails.AdjustValue();
				Else
					StringOfPropsForPriceKey.Value = FoundRow.Value;
				EndIf;
			Else
				StringOfPropsForPriceKey.Value = ThisObject[StringOfPropsForPriceKey.AttributeName];
			EndIf;
		EndDo;
	Else // for all the details for pricing
		SearchDetails_.Insert("OneToOneLink",          True);
		For Each String In AdditionalAttributes Do
			StringOfPropsForPriceKey = DetailsForPriceKey.Add();
			FillPropertyValues(StringOfPropsForPriceKey, String);
			StringOfPropsForPriceKey.AttributeName = String.Property;
			StringOfPropsForPriceKey.IsAddlAttribute = True;
			StringOfPropsForPriceKey.Used = True;
		EndDo;

		StringOfPropsForPriceKey = DetailsForPriceKey.Add();
		StringOfPropsForPriceKey.AttributeName   = "Description";
		StringOfPropsForPriceKey.Value       = Description;
		StringOfPropsForPriceKey.IsAddlAttribute = False;
		StringOfPropsForPriceKey.Used   = True;
		
		If TypeOf(Owner) = Type("CatalogRef.Products") Then
			StringOfPropsForPriceKey = DetailsForPriceKey.Add();
			StringOfPropsForPriceKey.AttributeName   = "Products";
			StringOfPropsForPriceKey.Value       = Owner;
			StringOfPropsForPriceKey.IsAddlAttribute = False;
			StringOfPropsForPriceKey.Used   = True;
		EndIf;
		
	EndIf;
	
	SearchDetails_.Insert("DetailsForPriceKey",       DetailsForPriceKey);
	
	Return SearchDetails_
	
EndFunction

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.KeysOfSetAccountingDimension", "DeletionMark");
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	
	Return Result;
	
EndFunction

Function GetCharacteristicsOfProductsForPricing(SearchDetails_)
	
	Return Catalogs.ItemsCharacteristicsForPricing.GetCharacteristicsOfProductsForPricing(SearchDetails_);
	
EndFunction 

#EndRegion

#EndIf
#EndIf
