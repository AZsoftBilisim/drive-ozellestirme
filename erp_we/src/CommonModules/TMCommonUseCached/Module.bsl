
#Region Public

// Returns the value of a constant by name
//
// Parameters:
// 	Name - String - Name of the constant
// 
// Returns:
//	Arbitrary - The value of the constant
// 
Function ConstantValue(Name) Export
	Return GeneralPurposeTMServerCall.ConstantValue(Name);
EndFunction

#EndRegion

#Region Private

#Region AdditionalAttributesAndInfo

// Returns the correspondence of a set of additional details (information) and functional options that affect the ability to use it.
//
// Returns:
//	Map of KeyAndValue - Where:
//		Key - Reference link.A set of additional requestionsreferences
//		The value - String is the names of the configuration files that this set is associated with.
//
Function RelationshipsBetweenBankingDetailsAndFunctionalOptions() Export
	
	ObjectsDetails = New Map;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	AdditionalAttributesAndInfoSets.Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
	|WHERE
	|	AdditionalAttributesAndInfoSets.Predefined
	|	AND AdditionalAttributesAndInfoSets.Parent = VALUE(Catalog.AdditionalAttributesAndInfoSets.EmptyRef)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		// Replace the first character "_" in the object name with "."
		ObjectName = Catalogs.AdditionalAttributesAndInfoSets.GetPredefinedItemName(Selection.Ref);
		
		SeparatorPosition = StrFind(ObjectName, "_");
		If SeparatorPosition = 0 Then
			Continue;
		EndIf;
		
		ObjectName = Left(ObjectName, SeparatorPosition - 1) + "." + Mid(ObjectName, SeparatorPosition + 1);
		
		// Objects with the prefix "Delete" are skipped
		If StrFind(Lower(ObjectName), ".delete") > 0 Then
			Continue;
		EndIf;
		
		MetadataObject = Metadata.FindByFullName(ObjectName);
		
		If MetadataObject <> Undefined Then
			
			ObjectDetails = ObjectDetails();
			ObjectDetails.Ref = Selection.Ref;
			ObjectDetails.MetadataObject = MetadataObject;
			
			ObjectsDetails.Insert(ObjectName, ObjectDetails);
			
		EndIf;
		
	EndDo;
	
	For Each MetaFO In Metadata.FunctionalOptions Do
		
		If Not Metadata.Constants.Contains(MetaFO.Location) Then
			Continue;
		EndIf;
		
		For Each ObjectDetails In ObjectsDetails Do
			If MetaFO.Content.Contains(ObjectDetails.Value.MetadataObject) Then
				ObjectDetails.Value.FunctionalOptions = ObjectDetails.Value.FunctionalOptions
					+ ?(ObjectDetails.Value.FunctionalOptions = "", "", ",") + MetaFO.Name;
			EndIf;
		EndDo;
		
	EndDo;
	
	Result = New Map;
	For Each ObjectDetails In ObjectsDetails Do
		Value = ObjectDetails.Value; // See ObjectDetails
		Result.Insert(Value.Ref, Value.FunctionalOptions);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * MetadataObject - MetadataObject - 
// * FunctionalOptions - String -
// * Ref - DocumentRef - 
Function ObjectDetails()
	ObjectDetails = New Structure;
	ObjectDetails.Insert("Ref");
	ObjectDetails.Insert("FunctionalOptions", "");
	ObjectDetails.Insert("MetadataObject");
	
	Return ObjectDetails;
EndFunction

#EndRegion

#Region MetadataObjectProperties

// Allows you to determine whether there is a property with the passed name among the object's details or standard details.
//
// Parameters:
//  MetadataObjectName - String - name of the metadata of the object to check for details in
//  AttributeName - String - name of the prop.
//
// Returns:
//  Boolean
//
Function HasObjectAttribute(MetadataObjectName, AttributeName) Export
	
	ObjectMetadata = Metadata.FindByFullName(MetadataObjectName);
	
	If Common.HasObjectAttribute(AttributeName, ObjectMetadata) Then
		Return True;
	EndIf;
	
	ObjectProperties = New Structure("StandardAttributes");
	FillPropertyValues(ObjectProperties, ObjectMetadata);
	
	If ObjectProperties.StandardAttributes = Undefined Then
		Return False;
	EndIf;
	
	Return Common.IsStandardAttribute(ObjectProperties.StandardAttributes, AttributeName);
	
EndFunction

#EndRegion

#Region ClearingInformationRegisters

// Returns information about data registers that have entries for the specified metadata.
//
// Parameters:
//	MetadataObjectNames - String - comma-separated full names
//		of metadata that we are looking for in the data registers.
//	OnlyLeadingMeasurements - Boolean - to search for references to metadata only in the leading dimensions.
//
// Returns:
//	Array of Structure - Structure properties:
//		* Name - String - the name of the register in the metadata
//		* Dimensions - Array of Structure - description of the register dimensions in which the links were found, with elements of the Structure with keys type:
//			* Name - String - The name of the dimension in metadata
//			* Types - Array of String - description of the dimension types where links are found.
//	
Function MeasurementMetadataInformationRegisters(MetadataObjectNames, OnlyLeadingMeasurements = False) Export
	
	MetadataNamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(MetadataObjectNames, ",",, True);
	
	ArrayOfRegisters = New Array;
	
	For Each Register In Metadata.InformationRegisters Do
		
		If Register.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
			Continue;
		EndIf;
		
		ArrayOfDimensions_ = New Array;
		
		For Each Dimension In Register.Dimensions Do
			
			If OnlyLeadingMeasurements And Not Dimension.Master Then
				Continue;
			EndIf;
			
			TypesArray = New Array;
			
			For Each DimensionType In Dimension.Type.Types() Do
				
				MetadataObject = Metadata.FindByType(DimensionType);
				If MetadataObject <> Undefined
				 And MetadataNamesArray.Find(MetadataObject.FullName()) <> Undefined Then
					
					TypesArray.Add(MetadataObject.FullName());
					
			 	EndIf;
				
			EndDo; // Types
			
			If TypesArray.Count() > 0 Then
				ArrayOfDimensions_.Add(New Structure("Name, Types", Dimension.Name, TypesArray));
			EndIf;
			
		EndDo; // Dimensions
		
		If ArrayOfDimensions_.Count() > 0 Then
			ArrayOfRegisters.Add(New Structure("Name, Dimensions", Register.Name, ArrayOfDimensions_));
		EndIf;
		
	EndDo; // Registers
	
	Return ArrayOfRegisters;
	
EndFunction

#EndRegion

#Region CheckingCorrectNumbering

// Checks the availability of service implementation documents for other Assets with the "Y" prefix"
// Used for correct numbering of documents with a 6-digit number.
//
// Returns:
// 	String - "0" if there are documents, "" if not.
//
Function AdditionalPrefixOfNumeratorDocumentsOfSaleOfGoods() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	               |	1 
	               |FROM
	               |	Document.CustomerInvoiceServicesAndAssets AS CustomerInvoiceServicesAndAssets
	               |WHERE
	               |	SUBSTRING(CustomerInvoiceServicesAndAssets.Number, 6, 1) = ""U""";
				   
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Return "0";
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#Region Classifiers

Function ArrayOfExcludedTypesOfCounterpartyCIForOutputInPartnerForm() Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	ContactInformationKinds.Ref
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogCounterparties)
	|	AND NOT ContactInformationKinds.Ref IN (
	|		VALUE(Catalog.ContactInformationKinds.PostalAddressOfCounterparty),
	|		VALUE(Catalog.ContactInformationKinds.LegalAddressOfCounterparty),
	|		VALUE(Catalog.ContactInformationKinds.ActualDataCounterpartyAddress),
	|		VALUE(Catalog.ContactInformationKinds.InternationalAddressOfCounterparty),
	|		VALUE(Catalog.ContactInformationKinds.FaxCounterparties)
	|	)
	|";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function ComplianceWithOKVEDCodes() Export

	Return CompaniesLocalization.MatchingCodesToNameFromTemplate("RNCEA2"); 

EndFunction

// Allows you to determine whether the specified document is the Registrar of the specified register.
//
// Parameters:
//  DocumentName - String - short name of the document to search for in the register registrars.
//  RegisterName - String - full name of the register (as in the metadata tree). Short names can be passed for accumulation registers
//                         . Example: "Lead Registers.Blocking of storage cells" or "product Organizations".
//
// Returns:
//  Boolean - the document is the registrar of the specified register.
//
Function ThisIsRegisterLogger(DocumentName, RegisterName) Export
	
	If StrFind(RegisterName, ".") > 0 Then
		RegisterMetadata = TMCommonUse.MetadataByName(RegisterName);
	Else// the short name of the register was passed - only accumulation registers
		RegisterMetadata = Metadata.AccumulationRegisters[RegisterName];
	EndIf;
	DocumentType = Type("DocumentRef."+DocumentName);
	Return RegisterMetadata.StandardAttributes.Recorder.Type.Types().Find(DocumentType) <> Undefined;
	
EndFunction

#EndRegion

#Region OperationsWithDocumentJournals 

// Returns the values of the business operations available to the user by the access group for the information database object.
//
// Parameters:
//	TableName - String - full name of the database object, for example, " data Register.Registry of documents".
//
// Returns:
//	Array of EnumRef.BusinessTransactions - 
//
Function AvailableBusinessTransactions(TableName) Export
	
	ValueType = Type("EnumRef.BusinessTransactions");
	
	AvailableBusinessTransactions = AccessManagement.AllowedDynamicListValues(TableName, ValueType,,True);
	
	Return AvailableBusinessTransactions;
	
EndFunction

#EndRegion

#Region Other
 
// The configuration uses only one language.
// 
// Returns:
//  Boolean - The configuration uses only one language
Function ConfigurationUsesOnlyOneLanguage() Export
	
	If Metadata.Languages.Count() = 1 Then
		Return True;
	EndIf;
	
	If Constants.UseAdditionalLanguage1.Get()
		Or Constants.UseAdditionalLanguage2.Get() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

Function ValuesOfEmptyDocumentRegistryKeys() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentRegistryKeys.Ref AS Ref
	|FROM
	|	Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
	|WHERE
	|	DocumentRegistryKeys.Key IN(&BlankValues)";
	
	ArrayOfEmptyValues_ = New Array;
	
	TypesOfKeys = Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type.Types();
	
	For Each KeyType In TypesOfKeys Do
		ArrayOfEmptyValues_.Add(PredefinedValue(Metadata.FindByType(KeyType).FullName() + ".EmptyRef"));
	EndDo;
	
	ArrayOfEmptyValues_.Add(Undefined);
	Query.SetParameter("BlankValues", ArrayOfEmptyValues_);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function AllowableDeviationOfAutomaticRounding() Export
	
	Return Constants.AllowableDeviationOfAutomaticRounding.Get();
	
EndFunction

Function UseMethodForTransferringGoodsBetweenOrganizations(TransferMethod, Organization = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod AS GoodsTransferMethod
	|FROM
	|	InformationRegister.CustomizeCustomerInvoiceIntercompany AS CustomizeCustomerInvoiceIntercompany
	|WHERE
	|	CustomizeCustomerInvoiceIntercompany.GoodsTransferMethod = &TransferMethod
	|	AND (&Organization = UNDEFINED OR CompanyCustomer = &Organization)";
	Query.SetParameter("TransferMethod", TransferMethod);
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

// Returns a flag indicating that the user has set the interface language
// corresponding to the main language of the information base.
//
// Returns:
//  Boolean
//
Function IsMainLanguage() Export
	
	Return Common.IsMainLanguage();
	
EndFunction

#EndRegion