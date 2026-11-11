#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the Catalog table.
//
// Parameters:
//	Variables1 - String - this method is not used, but it is mandatory if
//							other classifiers are used.
//
// Returns:
//		ValueTable - classifier table with columns:
//			* Code					- String - string representation of the classifier element code.
//			* Description			- String - name of the classifier element.
//			* UnitOfMeasureCode	- String - code of the unit of measurement for the ocean.
//			* TracedGoods	- Boolean - indicates that the product is registered in the traceability system.
//
Function TableOfClassifier(Val Variables1) Export
	
	TableOfIndicators = New ValueTable;
	
	TableOfIndicators.Columns.Add("Code", New TypeDescription("String", , New StringQualifiers(12)));
	TableOfIndicators.Columns.Add("Description",New TypeDescription("String", , New StringQualifiers(255)));
	TableOfIndicators.Columns.Add("UnitOfMeasureCode",New TypeDescription("String", , New StringQualifiers(4)));
	TableOfIndicators.Columns.Add("TracedGoods",New TypeDescription("Boolean"));

	Query = New Query;
	Query.Text =
	"SELECT
	|	FEACN.Ref AS Ref,
	|	FEACN.Code AS Code,
	|	FEACN.Description,
	|	FEACN.TracedGoods,
	|	FEACN.UnitOfMeasure
	|FROM
	|	Catalog.FEACN AS FEACN";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = TableOfIndicators.Add();
		NewRow.Code = Selection.Code;
		NewRow.Description = Selection.Description;
		NewRow.TracedGoods = Selection.TracedGoods;
		NewRow.UnitOfMeasureCode = Common.ObjectAttributeValue(Selection.UnitOfMeasure, "Code");
	EndDo;

	Return TableOfIndicators;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//  Array - a list of the names of the object's details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("UnitOfMeasure");
	Result.Add("TracedGoods");
	
	Return Result;
	
EndFunction

Function GetServiceElements() Export
	
	CodeCompliance = New Map;
	CodeCompliance.Insert(False, FindByDescription("nonprimary owngoods"));
	CodeCompliance.Insert(True, FindByDescription("rawmaterial owngoods"));
	
	Return CodeCompliance;
	
EndFunction

// Checks whether the Attributes of import accounting and traceability of items
// that use the specified HS code need to be updated.
//
// Parameters:
//	Object - CatalogObject.FEACN, FormDataStructure - the processed element of the Catalog classificatornved.
//	
// Returns:
//	Boolean
//
Function ItIsRequiredToChangeAttributesOfItemSTraceability(Object) Export
	
	Return False;
	
EndFunction

// Updates the Attributes of the item's traceability, 
// in accordance with the Attributes of the specified element of the Catalog CLASSIFICATORNVED.
//
// Parameters:
//	Ref - CatalogRef.FEACN - element of the Catalog classificatornved.
//	
Procedure ChangeAttributesOfItemTraceability(Ref) Export
	
	
EndProcedure

// Creating or updating elements of the FEA
//
// Parameters:
//  ServiceData_ - ValueTable - data received from the service. Columns:
//                    * Id           - Number  - ID of the element on the service side (service);
//                    * Code                     - String - classifier element code in the format "XXXX XX XXX X";
//                    * ParentCode             - String - code of the parent element in the format with spaces;
//                    * Order                 - Number  - field for ordering elements (service);
//                    * ValidityStartDate      - Date   - start date of the classifier element;
//                    * ValidityEndDate   - Date   - expiration date of the classifier element;
//                    * Description            - String - name of the element;
//                    * DescriptionFull      - String - the name of the element, including the names of the parents;
//                    * LongDesc                - String - element description;
//                    * OceaniaCode                 - String - code of the OCEANA Catalog element;
//                    * RawMaterial                - Boolean - a sign indicating that the goods belong to raw materials;
//                    * CustomsDuty       - String - customs duty rate and additional information;
//                    * VATRate               - String - VAT rate;
//                    * SubjectToDisposal      - Boolean - a sign indicating the need to dispose of goods;
//                    * ChangingCompositionOfGoods - Boolean - a flag indicating a change in the composition of products
//                                                         related to the element;
//  Cancel - Boolean - if True, the update will be considered unsuccessful.
//
Procedure CreateUpdateTaxCodeElementsFromCloudClassifier(ServiceData_, Cancel) Export
	
	ServiceDataCodes = ServiceData_.UnloadColumn("Code");
	ExistingElementsOfFEA = ElementsByCode(ServiceDataCodes);

	For Each ServiceDataString In ServiceData_ Do
		
		// We load only elements whose rows do not have subordinate elements.
		If ServiceDataString.DescendantsTotal > 0 Then
			Continue;
		EndIf;
		
		CreateUpdateClassifierElement(ServiceDataString, ExistingElementsOfFEA);
		
	EndDo;
	
EndProcedure

// The function searches by code for elements in the HS Classifier Catalog.
// If there are none, then it creates elements of the Catalog in accordance with the classifier of the Customs Code of Foreign Economic Activity of the EAEU.
// If there is, it updates the Attributes of this element.
//
// Parameters:
//	ItemProperties - ValueTableRow,
//	ExistingElementsOfFEA - Map of String, CatalogRef.FEACN - Matching Catalog elements and codes
//
// Returns:
//	CatalogRef.FEACN - link to the classifier element.
//
Function CreateUpdateClassifierElement(ItemProperties, ExistingElementsOfFEA = Undefined) Export
	
	StandardizedCode = NormalizeHSCode(ItemProperties.Code);
	
	If ValueIsFilled(ExistingElementsOfFEA) Then
		ExistingElementsOfTaxCodeToSearchFor = ExistingElementsOfFEA;
	Else
		ServiceDataCodes = CommonClientServer.ValueInArray(ItemProperties.Code);
		ExistingElementsOfTaxCodeToSearchFor = ElementsByCode(ServiceDataCodes);
	EndIf;
	
	ExistingElement = ExistingElementsOfTaxCodeToSearchFor.Get(StandardizedCode);
	If ExistingElement = Undefined Then
		TaxCodeOfObject = Catalogs.FEACN.CreateItem();
	Else
		TaxCodeOfObject = ExistingElement.GetObject();
		LockDataForEdit(ExistingElement);
	EndIf;
	
	TaxCodeOfObject.Code = StandardizedCode;
	TaxCodeOfObject.Description = ItemProperties.Description;
	TaxCodeOfObject.DescriptionFull = ItemProperties.DescriptionFull;
	TaxCodeOfObject.Commodity = ItemProperties.RawMaterial;
	
	Map = Catalogs.PackagesAndUnitsOfMeasure.FillInUnitsFromClassifier(ItemProperties.OceaniaCode);
		
	If Map <> Undefined Then
		TaxCodeOfObject.UnitOfMeasure = Map[ItemProperties.OceaniaCode];
	EndIf;
	
	TaxCodeOfObject.Write();
	
	Return TaxCodeOfObject.Ref;
	
EndFunction

#EndRegion

#Region Private

Function ElementsByCode(ServiceTaxCodes)
	
	CodeMatches = New Map;
	If Not ValueIsFilled(ServiceTaxCodes) Then
		Return CodeMatches;
	EndIf;
	
	HSCodes = New Array;
	For Each LineOfServiceSTaxCode In ServiceTaxCodes Do
		HSCodes.Add(NormalizeHSCode(LineOfServiceSTaxCode));
	EndDo;
	
	Query = New Query;
	Query.SetParameter("HSCodes", HSCodes);
	Query.Text =
	"SELECT
	|	FEACN.Ref AS Ref,
	|	FEACN.Code AS Code
	|FROM
	|	Catalog.FEACN AS FEACN
	|WHERE
	|	FEACN.Code IN(&HSCodes)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CodeMatches.Insert(Selection.Code, Selection.Ref);
	EndDo;
	
	Return CodeMatches;
	
EndFunction

Function NormalizeHSCode(FullHSCode) 
	// In the service, the HS code is specified with spaces, such as "0101 30 000 0".
	// In the configuration, the code without spaces is used - "0101300000".
	// Therefore, you need to get rid of the gaps.
	Return StrReplace(FullHSCode, " ", "");
EndFunction

#EndRegion

#EndIf
