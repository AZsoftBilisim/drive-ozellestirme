#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	
	Item = Items.Add();
	Item.PredefinedDataName = "EXCLUDINGVAT";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Không thuế GTGT';
																					|ru = 'Без НДС';
																					|en = 'Excluding VAT';
																					|it = 'Без НДС';
																					|pl = 'Netto';
																					|tr = 'KDV hariç'", LanguagesCodes); // @NStr-2
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.VATRates - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export

EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	VATAccountingERP.GetDataForSelectingVATRate(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

Procedure CreateInitialFillItems(FirstRun = False) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		RateWithoutVATLink = Catalogs.VATRates.EXCLUDINGVAT;
		
		DataLock = New DataLock();
		LockItem = DataLock.Add("Catalog.VATRates");
		LockItem.SetValue("Ref", RateWithoutVATLink);
		LockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		RateWithoutVATItem = RateWithoutVATLink.GetObject();
		
		Common.SetAttributeValue(RateWithoutVATItem, "Description", NStr("vi = 'Không thuế GTGT';
																		|ru = 'Без НДС';
																		|en = 'Excluding VAT'; fa = 'بدون مالیات بر ارزش افزوده';
																		|it = 'IVA esclusa';
																		|pl = 'Netto';
																		|tr = 'KDV hariç'", Common.DefaultLanguageCode()));
		RateWithoutVATItem.Rate1 = 0;
		
		RateWithoutVATItem.VATTaxationTypes.Clear();
		
		VATTaxationType = RateWithoutVATItem.VATTaxationTypes.Add();
		VATTaxationType.VATTaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
		
		VATTaxationType = RateWithoutVATItem.VATTaxationTypes.Add();
		VATTaxationType.VATTaxationType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		
		InfobaseUpdate.WriteData(RateWithoutVATItem);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	VATAccountingLocalization.FillInCatalogOfVATRates();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
