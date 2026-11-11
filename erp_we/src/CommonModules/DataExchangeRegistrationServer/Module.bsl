///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region SelectiveDataRegistration

// Returns the id of the selective registration mode that does not use selectiveness.
// (In this mode, all objects are considered modified.)
//
// Returns:
//  String - The id of the "Disabled" selective registration mode.
//
Function SelectiveRegistrationModeDisabled() Export
	
	Return "Disabled";
	
EndFunction

// Returns the id of the selective registration mode that checks if an object is modified by its "Modified" property.
// 
//
// Returns:
//  String - The id of the "Modified" selective registration mode.
//
Function SelectiveRegistrationModeModification() Export
	
	Return "Modified";
	
EndFunction

// Returns the id of the selective registration mode that checks the object's attribute state before writing and after writing.
// The list of checked attributes is generated according to object properties specified in the conversion rules.
// This mode supports only CRDE exchange plans.
// 
//
// Returns:
//  String - The id of the "AccordingToXMLRules" selective registration mode.
//
Function SelectiveRegistrationModeByXMLRules() Export
	
	Return "AccordingToXMLRules";
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region SelectiveDataRegistration

Function SelectiveObjectsRegistrationRulesTableInitialization() Export
	
	TypeDescriptionNumber = New TypeDescription("Number");
	StringTypeDetails = New TypeDescription("String");
	DetailsOfStructureType = New TypeDescription("Structure");
	
	ResultTable1 = New ValueTable;
	
	ResultTable1.Columns.Add("Order",                        TypeDescriptionNumber);
	ResultTable1.Columns.Add("ObjectName",                     StringTypeDetails);
	ResultTable1.Columns.Add("ObjectTypeString",              StringTypeDetails);
	ResultTable1.Columns.Add("ExchangePlanName",                 StringTypeDetails);
	ResultTable1.Columns.Add("TabularSectionName",              StringTypeDetails);
	ResultTable1.Columns.Add("RegistrationAttributes",           StringTypeDetails);
	ResultTable1.Columns.Add("RegistrationAttributesStructure", DetailsOfStructureType);
	
	ResultTable1.Indexes.Add("ObjectName, ObjectTypeString, ExchangePlanName, TabularSectionName");
	
	Return ResultTable1;
	
EndFunction

Function NewParametersOfExchangePlanDataSelectiveRegistration(ExchangePlanName) Export
	
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
		
		Return New Structure;
		
	EndIf;
	
	SelectiveRegistrationParameters = New Structure;
	SelectiveRegistrationParameters.Insert("IsXDTOExchangePlan", False);
	SelectiveRegistrationParameters.Insert("RegistrationAttributesTable", Undefined);
	
	BeforeGenerateNewParametersOfExchangePlanDataSelectiveRegistration(SelectiveRegistrationParameters, ExchangePlanName);
	
	Return SelectiveRegistrationParameters;
	
EndFunction

Function ObjectModifiedForExchangePlan(Source, MetadataObject, ExchangePlanName, WriteMode, RecordObjectToExport) Export
	
	Try
		
		ObjectIsModified = ObjectIsModified(Source, MetadataObject, ExchangePlanName, WriteMode, RecordObjectToExport);
		
	Except
		
		TemplateRow = NStr("vi = 'Lỗi xác định chỉnh sửa đối tượng: %1';
							|ru = 'Ошибка определения модифицированности объекта: %1';
							|en = 'Cannot determining whether the object was modified: %1'; fa = 'Cannot determining whether the object was modified: %1';
							|it = 'Errore durante la determinazione della modifica dell''oggetto: %1';
							|pl = 'Błąd określenia możliwości modyfikowania obiektu: %1';
							|tr = 'Nesnenin değiştirilmesini belirlerken bir hata oluştu: %1'", Common.DefaultLanguageCode());
		Raise StrTemplate(TemplateRow, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return ObjectIsModified;
	
EndFunction

Function DetermineObjectVersionsChanges(Object, RegistrationAttributesTableRow) Export
	
	If IsBlankString(RegistrationAttributesTableRow.TabularSectionName) Then // Object header attributes.
		
		RegistrationAttributesTableObjectVersionBeforeChange = HeaderRegistrationAttributesBeforeChange(Object, RegistrationAttributesTableRow);
		
		RegistrationAttributesTableObjectVersionAfterChange = HeaderRegistrationAttributesAfterChange(Object, RegistrationAttributesTableRow);
		
	Else // Object table attributes.
		
		// Checking if it is an object tabular section not a register table.
		If Object.Metadata().TabularSections.Find(RegistrationAttributesTableRow.TabularSectionName) = Undefined Then
			Return False;
		EndIf;
		
		RegistrationAttributesTableObjectVersionBeforeChange = TabularSectionRegistrationAttributesBeforeChange(Object, RegistrationAttributesTableRow);
		
		RegistrationAttributesTableObjectVersionAfterChange = TabularSectionRegistrationAttributesAfterChange(Object, RegistrationAttributesTableRow);
		
	EndIf;
	
	Return Not RegistrationAttributesTablesSimilar(RegistrationAttributesTableObjectVersionBeforeChange, RegistrationAttributesTableObjectVersionAfterChange, RegistrationAttributesTableRow);
	
EndFunction

#EndRegion

Function RegistrationRuleEventName() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu.Quy tắc ghi nhận đối tượng';
				|ru = 'Обмен данными.Правила регистрации объектов';
				|en = 'Data exchange.Object registration rules'; fa = 'Data exchange.Object registration rules';
				|it = 'Scambio di dati.Regole di registrazione oggetti';
				|pl = 'Wymiana danych.Reguły rejestracji obiektów';
				|tr = 'Veri değişimi. Nesnelerin kayıt kuralları'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Private

#Region SelectiveDataRegistration

Function ModificationFlagFromPCR(Source, ExchangePlanName, MetadataObject, RegistrationAttributesTable)
	
	If TypeOf(RegistrationAttributesTable) <> Type("ValueTable") Then
		
		// If no selective object registration table is found, it is assumed that no filters are applied
		Return True;
		
	EndIf;
	
	ObjectName = MetadataObject.FullName();
	
	ObjectSelectiveRegistrationAttributes = ObjectSelectiveRegistrationAttributes(RegistrationAttributesTable, ObjectName, ExchangePlanName);
	If ObjectSelectiveRegistrationAttributes.Count() = 0 Then
		
		// If the table has no rows with SOR attributes, assume that
		// no filters are applied and the object is always modified.
		Return True;
		
	EndIf;
	
	For Each TableRow In ObjectSelectiveRegistrationAttributes Do
		
		HasObjectsVersionsChanges = DetermineObjectVersionsChanges(Source, TableRow);
		If HasObjectsVersionsChanges Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	// If an object reaches the end of the cycle, it means its registration attributes didn't change. Don't need to register changes.
	Return False;
	
EndFunction

Function ValueOfInfobaseObjectModificationProperty(Source)
	
	Try
		
		Return Source.Modified();
		
	Except
		
		Return True;
		
	EndTry;
	
EndFunction

Function DocumentPostingChanged(Source, WriteMode)
	
	Return (Source.Posted And WriteMode = DocumentWriteMode.UndoPosting)
	 Or (Not Source.Posted And WriteMode = DocumentWriteMode.Posting);
	
EndFunction

Function InitializeTablesOfCommonAttributes()
	
	CommonAttributeTable = New ValueTable;
	CommonAttributeTable.Columns.Add("CommonAttribute");
	CommonAttributeTable.Columns.Add("MetadataObject");
	
	CommonAttributeTable.Indexes.Add("CommonAttribute, MetadataObject");
	
	Return CommonAttributeTable;
	
EndFunction

Function ObjectRegistrationAttributesTableMetadata(CurrentObjetMetadata, RequiredTabularSectionName)
	
	MetaTest = New Structure("TabularSections, StandardTabularSections, RegisterRecords");
	FillPropertyValues(MetaTest, CurrentObjetMetadata);
	MetaTables = New Array;
	
	CandidateName = Upper(RequiredTabularSectionName);
	
	For Each KeyValue In MetaTest Do
		TableMetaCollection = KeyValue.Value; // MetadataObjectCollection, MetadataObjectPropertyValueCollection, StandardTabularSectionDescriptions
		If TableMetaCollection <> Undefined Then
			
			For Each MetaTable In TableMetaCollection Do
				If Upper(MetaTable.Name) = CandidateName Then
					MetaTables.Add(MetaTable);
				EndIf;
			EndDo;
			
		EndIf;
	EndDo;
	If MetaTables.Count() > 0 Then
		Return MetaTables;
	EndIf;

	Return Undefined;
	
EndFunction

Function ObjectIsModified(Source, MetadataObject, ExchangePlanName, WriteMode, RecordObjectToExport)
	
	If RecordObjectToExport
		Or Source.IsNew()
		Or Source.DataExchange.Load Then
		
		// Always register changes:
		// - For register record sets
		// - When an object is permanently deleted
		// - For objects recorded as part of data exchange
		// 
		Return True;
		
	ElsIf WriteMode <> Undefined
		And DocumentPostingChanged(Source, WriteMode) Then
		
		// If the Posted flag is changed, the document is considered modified.
		Return True;
		
	EndIf;
	
	SelectiveRegistrationMode = DataExchangeRegistrationCached.ExchangePlanDataSelectiveRegistrationMode(ExchangePlanName);
	If SelectiveRegistrationMode = SelectiveRegistrationModeDisabled() Then
		
		// This exchange plan does not use selective registration
		Return True;
		
	ElsIf SelectiveRegistrationMode = SelectiveRegistrationModeModification() Then
		
		Return ValueOfInfobaseObjectModificationProperty(Source);
		
	Else
		
		SelectiveRegistrationParameters = DataExchangeRegistrationCached.SelectiveRegistrationParametersByExchangeNodeName(ExchangePlanName);
		If TypeOf(SelectiveRegistrationParameters) = Type("Structure") Then
			
			Return ModificationFlagFromPCR(Source, ExchangePlanName, MetadataObject, SelectiveRegistrationParameters.RegistrationAttributesTable);
			
		Else
			
			// Generate new selective registration parameters and write them to the information register.
			
			
		EndIf;
		
	EndIf;
	
	// This is a stub in case there are temporary registration parameters without the required field.
	// This is abnormal behavior and if it happens, consider the selective registration passed.
	Return True;
	
EndFunction

Function AttributeIsFoundInTabularSectionOfObjectRegistrationAttributes(MetadataTables, NameOfSoughtAttribute)
	
	MetaTest = New Structure;
	MetaTest.Insert("Attributes", Undefined);
	MetaTest.Insert("StandardAttributes", Undefined);
	MetaTest.Insert("Dimensions", Undefined);
	MetaTest.Insert("Resources", Undefined);
	FillPropertyValues(MetaTest, MetadataTables);
	
	CandidateName = Upper(NameOfSoughtAttribute);
	Correspondence = False;
	If TypeOf(MetadataTables) = Type("MetadataObject") And Common.IsAccountingRegister(MetadataTables) Then
		Correspondence = MetadataTables.Correspondence;
		// Cannot check the Dr and Cr extra dimensions as they are missing from the dimensions.
		// "Account" is a standard attribute without the balance flag.
		If CandidateName = "EXTDIMENSIONDR" Or CandidateName = "EXTDIMENSIONCR"
			Or CandidateName = "ACCOUNTDR" Or CandidateName = "ACCOUNTCR" Then
			Return True;
		EndIf;
		
		// Take into account exchange plans without "Correspondences", "ExtDimension", and "Account"
		If Correspondence = False Then
			
			If CandidateName = "EXTDIMENSION"
				Or CandidateName = "ACCOUNT" Then
				Return True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	For Each KeyValue In MetaTest Do
		MetaCollectionOfAttribuutes = KeyValue.Value; // MetadataObjectCollection, StandardAttributeDescriptions
		
		If MetaCollectionOfAttribuutes <> Undefined Then
			
			For Each MetaAttribute In MetaCollectionOfAttribuutes Do
				
				If Upper(MetaAttribute.Name) = CandidateName Then
					Return True;
				EndIf;
				
				If (KeyValue.Key = "Dimensions" Or KeyValue.Key = "Resources") And Correspondence And Not MetaAttribute.Balance Then
					If Upper(MetaAttribute.Name) + "DR" = CandidateName
						Or Upper(MetaAttribute.Name) + "CR" = CandidateName Then
						Return True;
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ObjectSelectiveRegistrationAttributes(RegistrationAttributesTable, ObjectName, ExchangePlanName)
	
	If RegistrationAttributesTable.Count() = 0 Then
		
		Return RegistrationAttributesTable;
		
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ExchangePlanName", ExchangePlanName);
	Filter.Insert("ObjectName",     ObjectName);
	
	TableOfSelectiveRegistrationAttributes = RegistrationAttributesTable.Copy(Filter);
	TableOfSelectiveRegistrationAttributes.Sort("Order Asc");
	
	Return TableOfSelectiveRegistrationAttributes;
	
EndFunction

Function HeaderRegistrationAttributesBeforeChange(Object, RegistrationAttributesTableRow)
	
	QueryTextTemplate2 =
	"SELECT
	|	&RegistrationAttributes
	|FROM
	|	&MetadataTableName AS CurrentObject
	|WHERE
	|	CurrentObject.Ref = &Ref";
	
	QueryText = StrReplace(QueryTextTemplate2, "&RegistrationAttributes", RegistrationAttributesTableRow.RegistrationAttributes);
	QueryText = StrReplace(QueryText, "&MetadataTableName", RegistrationAttributesTableRow.ObjectName);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Return Query.Execute().Unload();
	
EndFunction

Function TabularSectionRegistrationAttributesBeforeChange(Object, RegistrationAttributesTableRow)
	
	QueryTextTemplate2 = 
	"SELECT
	|	&RegistrationAttributes
	|FROM
	|	&MetadataTableName AS CurrentObjectTabularSectionName
	|WHERE
	|	CurrentObjectTabularSectionName.Ref = &Ref";
	
	ReplacementString = StringFunctionsClientServer.SubstituteParametersToString("%1.%2", RegistrationAttributesTableRow.ObjectName, RegistrationAttributesTableRow.TabularSectionName);
	
	QueryText = StrReplace(QueryTextTemplate2, "&RegistrationAttributes", RegistrationAttributesTableRow.RegistrationAttributes);
	QueryText = StrReplace(QueryText, "&MetadataTableName", ReplacementString);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Return Query.Execute().Unload();
	
EndFunction

Function HeaderRegistrationAttributesAfterChange(Object, RegistrationAttributesTableRow)
	
	RegistrationAttributesStructure = RegistrationAttributesTableRow.RegistrationAttributesStructure;
	
	RegistrationAttributesTable = New ValueTable;
	
	For Each RegistrationAttribute In RegistrationAttributesStructure Do
		
		RegistrationAttributesTable.Columns.Add(RegistrationAttribute.Key);
		
	EndDo;
	
	TableRow = RegistrationAttributesTable.Add();
	
	For Each RegistrationAttribute In RegistrationAttributesStructure Do
		
		TableRow[RegistrationAttribute.Key] = Object[RegistrationAttribute.Key];
		
	EndDo;
	
	Return RegistrationAttributesTable;
EndFunction

Function TabularSectionRegistrationAttributesAfterChange(Object, RegistrationAttributesTableRow)
	
	RegistrationAttributesTable = Object[RegistrationAttributesTableRow.TabularSectionName].Unload(, RegistrationAttributesTableRow.RegistrationAttributes);
	
	Return RegistrationAttributesTable;
	
EndFunction

Function RegistrationAttributesTablesSimilar(Table1, Table2, RegistrationAttributesTableRow)
	
	Table1.Columns.Add("ChangeRecordAttributeTableIterator");
	Table1.FillValues(+1, "ChangeRecordAttributeTableIterator");
	
	Table2.Columns.Add("ChangeRecordAttributeTableIterator");
	Table2.FillValues(-1, "ChangeRecordAttributeTableIterator");
	
	ResultTable1 = Table1.Copy();
	
	CommonClientServer.SupplementTable(Table2, ResultTable1);
	
	ResultTable1.GroupBy(RegistrationAttributesTableRow.RegistrationAttributes, "ChangeRecordAttributeTableIterator");
	
	SameRowsCount = ResultTable1.FindRows(New Structure ("ChangeRecordAttributeTableIterator", 0)).Count();
	
	TableRowsCount = ResultTable1.Count();
	
	Return SameRowsCount = TableRowsCount;
	
EndFunction

Function IsCommonAttribute(CommonAttribute, MDOName, CommonAttributeTable)
	
	SearchParameters = New Structure("CommonAttribute, MetadataObject", CommonAttribute, MDOName);
	FoundValues = CommonAttributeTable.FindRows(SearchParameters);
	
	If FoundValues.Count() > 0 Then
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure CheckObjectChangeRecordAttributes(RegistrationAttributesTable)
	
	For Each TableRow In RegistrationAttributesTable Do
		
		Try
			ObjectType = Type(TableRow.ObjectTypeString);
		Except
			
			MessageString = NStr("vi = 'Chưa xác định kiểu đối tượng: %1';
								|ru = 'Тип объекта не определен: %1';
								|en = 'Undefined object type: %1'; fa = 'Undefined object type: %1';
								|it = 'Il tipo dell''oggetto non è specificato: %1';
								|pl = 'Nie zdefiniowano typu obiektu: %1';
								|tr = 'Nesne türü belirlenmemiş: %1'", Common.DefaultLanguageCode());
			MessageString = StrTemplate(MessageString, TableRow.ObjectTypeString);
			WriteToExecutionProtocol(MessageString);
			Continue;
			
		EndTry;
		
		MetadataObjectsList = Metadata.FindByType(ObjectType);
		
		// Checking reference types only.
		If Not Common.IsRefTypeObject(MetadataObjectsList) Then
			Continue;
		EndIf;
		
		CommonAttributeTable = InitializeTablesOfCommonAttributes();
		FillCommonAttributeTable(CommonAttributeTable);
		
		If IsBlankString(TableRow.TabularSectionName) Then // Header attributes.
			
			For Each Attribute In TableRow.RegistrationAttributesStructure Do
				
				If Common.IsTask(MetadataObjectsList) Then
					
					If Not (MetadataObjectsList.Attributes.Find(Attribute.Key) <> Undefined
						Or  MetadataObjectsList.AddressingAttributes.Find(Attribute.Key) <> Undefined
						Or  DataExchangeServer.IsStandardAttribute(MetadataObjectsList.StandardAttributes, Attribute.Key)
						Or  IsCommonAttribute(Attribute.Key, MetadataObjectsList.FullName(), CommonAttributeTable)) Then
						
						MessageString = NStr("vi = 'Đã chỉ ra không đúng các mục tin của phần đầu đối tượng ""%1"". Mục tin ""%2"" không tồn tại.';
											|ru = 'Неправильно указаны реквизиты шапки объекта ""%1"". Реквизит ""%2"" не существует.';
											|en = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.'; fa = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.';
											|it = 'Sono indicati requisiti errati del titolo dell''oggetto ""%1"". Requisito ""%2"" non esiste.';
											|pl = 'Niepoprawne szczegóły nagłówka obiektu ""%1"". Rekwizyt ""%2"" nie istnieje.';
											|tr = '""%1"" nesne başlığının öznitelikleri yanlış belirtildi. Öznitelik ""%2"" mevcut değil.'");
						MessageString = StrTemplate(MessageString, String(MetadataObjectsList), Attribute.Key);
						WriteToExecutionProtocol(MessageString);
						
					EndIf;
					
				ElsIf Common.IsChartOfAccounts(MetadataObjectsList) Then
					
					If Not (MetadataObjectsList.Attributes.Find(Attribute.Key) <> Undefined
						Or  MetadataObjectsList.AccountingFlags.Find(Attribute.Key) <> Undefined
						Or  DataExchangeServer.IsStandardAttribute(MetadataObjectsList.StandardAttributes, Attribute.Key)
						Or  IsCommonAttribute(Attribute.Key, MetadataObjectsList.FullName(), CommonAttributeTable)) Then
						
						MessageString = NStr("vi = 'Đã chỉ ra không đúng các mục tin của phần đầu đối tượng ""%1"". Mục tin ""%2"" không tồn tại.';
											|ru = 'Неправильно указаны реквизиты шапки объекта ""%1"". Реквизит ""%2"" не существует.';
											|en = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.'; fa = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.';
											|it = 'Sono indicati requisiti errati del titolo dell''oggetto ""%1"". Requisito ""%2"" non esiste.';
											|pl = 'Niepoprawne szczegóły nagłówka obiektu ""%1"". Rekwizyt ""%2"" nie istnieje.';
											|tr = '""%1"" nesne başlığının öznitelikleri yanlış belirtildi. Öznitelik ""%2"" mevcut değil.'");
						MessageString = StrTemplate(MessageString, String(MetadataObjectsList), Attribute.Key);
						WriteToExecutionProtocol(MessageString);
						
					EndIf;
					
				Else
					
					If Not (MetadataObjectsList.Attributes.Find(Attribute.Key) <> Undefined
						Or  DataExchangeServer.IsStandardAttribute(MetadataObjectsList.StandardAttributes, Attribute.Key)
						Or  IsCommonAttribute(Attribute.Key, MetadataObjectsList.FullName(), CommonAttributeTable)) Then
						
						MessageString = NStr("vi = 'Đã chỉ ra không đúng các mục tin của phần đầu đối tượng ""%1"". Mục tin ""%2"" không tồn tại.';
											|ru = 'Неправильно указаны реквизиты шапки объекта ""%1"". Реквизит ""%2"" не существует.';
											|en = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.'; fa = 'Invalid header attributes of the ""%1"" object. Attribute ""%2"" does not exist.';
											|it = 'Sono indicati requisiti errati del titolo dell''oggetto ""%1"". Requisito ""%2"" non esiste.';
											|pl = 'Niepoprawne szczegóły nagłówka obiektu ""%1"". Rekwizyt ""%2"" nie istnieje.';
											|tr = '""%1"" nesne başlığının öznitelikleri yanlış belirtildi. Öznitelik ""%2"" mevcut değil.'");
						MessageString = StrTemplate(MessageString, String(MetadataObjectsList), Attribute.Key);
						WriteToExecutionProtocol(MessageString);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		Else
			
			// Tabular section, standard tabular section, records.
			MetaTables = ObjectRegistrationAttributesTableMetadata(MetadataObjectsList, TableRow.TabularSectionName);
			If MetaTables = Undefined Then
				
				MessageString = NStr("vi = 'Phần bảng (phần bảng chuẩn, bản ghi kết chuyển) ""%1"" của đối tượng ""%2"" không tồn tại.';
									|ru = 'Табличная часть (стандартная табличная часть, движения) ""%1"" объекта ""%2"" не существует.';
									|en = 'The ""%1"" table (or a standard table, or a list of register records) of the ""%2"" object does not exist.'; fa = 'The ""%1"" table (or a standard table, or a list of register records) of the ""%2"" object does not exist.';
									|it = 'La parte tabulare (parte tabulare standard, movimentazioni) ""%1"" dell''oggetto ""%2"" non esiste.';
									|pl = 'Część tabelaryczna (standardowa część tabelaryczna, ruch) ""%1"" obiekt ""%2"" nie istnieje.';
									|tr = '""%1"" nesnenin ""%2"" sekme bölümü (standart sekme bölümü, hareketler) mevcut değil.'");
				WriteToExecutionProtocol(StrTemplate(MessageString, TableRow.TabularSectionName, MetadataObjectsList));
				Continue;
				
			EndIf;
			
			// Trying to find every attribute somewhere.
			For Each Attribute In TableRow.RegistrationAttributesStructure Do
				
				PropsFound = False;
				For Each MetaTable In MetaTables Do
					PropsFound = AttributeIsFoundInTabularSectionOfObjectRegistrationAttributes(MetaTable, Attribute.Key);
					If PropsFound Then
						Break;
					EndIf;
				EndDo;
				
				If Not PropsFound Then
					
					MessageString = NStr("vi = 'Mục tin ""%3"" không tồn tại trong phần bảng (phần bảng chuẩn, bản ghi kết chuyển) ""%1"" của đối tượng ""%2"".';
										|ru = 'Реквизит ""%3"" не существует в табличной части (стандартной табличной части, движениях) ""%1"" объекта ""%2"".';
										|en = 'The ""%3"" attribute is not found in the ""%1"" table (or a standard table, or a list of register records) of the ""%2"" object.'; fa = 'The ""%3"" attribute is not found in the ""%1"" table (or a standard table, or a list of register records) of the ""%2"" object.';
										|it = 'Il requisito ""%3"" non esiste nella parte tabulare (parte tabulare standard, movimentazioni) ""%1"" dell''oggetto ""%2"".';
										|pl = 'Rekwizyty ""%3"" nie istnieją w części tabelarycznej (standardowa część tabelaryczna, ruchy) ""%1"" obiektu ""%2"".';
										|tr = '""%3"" nesnenin ""%1"" tablo bölümünde (standart tablo bölümü, hareket) ""%2"" özniteliği mevcut değil.'");
					WriteToExecutionProtocol(StrTemplate(MessageString, TableRow.TabularSectionName, MetadataObjectsList, Attribute.Key));
					Break;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SupplementChangeRecordAttributeTable(RowsArray, RegistrationAttributesTable)
	
	TableRow = RegistrationAttributesTable.Add();
	
	ResultingStructure = New Structure;
	RegistrationAttributesAsString = "";
	
	For Each TableRowResult In RowsArray Do
		
		RegistrationAttributesStructure = TableRowResult.RegistrationAttributesStructure;
		For Each RegistrationAttribute In RegistrationAttributesStructure Do
			
			ResultingStructure.Insert(RegistrationAttribute.Key);
			RegistrationAttributesAsString = RegistrationAttributesAsString + RegistrationAttribute.Key + ", ";
			
		EndDo;
		
	EndDo;
	
	StringFunctionsClientServer.DeleteLastCharInString(RegistrationAttributesAsString, 2);
	
	TableRow.Order                        = RowsArray[0].Order;
	TableRow.ObjectName                     = RowsArray[0].ObjectName;
	TableRow.ObjectTypeString              = RowsArray[0].ObjectTypeString;
	TableRow.TabularSectionName              = RowsArray[0].TabularSectionName;
	TableRow.RegistrationAttributesStructure = ResultingStructure;
	TableRow.RegistrationAttributes           = RegistrationAttributesAsString;
	
EndProcedure

Procedure AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, TabularSectionName, Order, PropertiesTable, ResultTable1)
	
	RegistrationAttributesStructure = New Structure;
	
	PCRRowsArray = PropertiesTable.FindRows(New Structure("IsFolder", False));
	For Each PCR In PCRRowsArray Do
		
		PCRSource = PCR.Source;
		
		// Checking for invalid characters in the row.
		If IsBlankString(PCRSource)
			Or Left(PCRSource, 1) = "{" Then
			
			Continue;
		EndIf;
		
		Try
			RegistrationAttributesStructure.Insert(PCRSource);
		Except
			WriteLogEvent(NStr("vi = 'Trao đổi dữ liệu.Kết nhập quy tắc chuyển đổi';
								|ru = 'Обмен данными.Загрузка правил конвертации';
								|en = 'Data exchange.Import conversion rules'; fa = 'Data exchange.Import conversion rules';
								|it = 'Scambio di dati.Download delle regole di conversione';
								|pl = 'Wymiana danych.Pobieranie reguł konwersji';
								|tr = 'Veri değişimi. Dönüştürme kuralı içe aktarma'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	TableRowResult = ResultTable1.Add();
	
	TableRowResult.Order                        = Order;
	TableRowResult.ObjectName                     = ObjectName;
	TableRowResult.ObjectTypeString              = ObjectTypeString;
	TableRowResult.TabularSectionName              = TabularSectionName;
	TableRowResult.RegistrationAttributesStructure = RegistrationAttributesStructure; 
	
EndProcedure

Procedure WriteToExecutionProtocol(ErrorText)
	
	DataProcessorObject = DataProcessors.InfobaseObjectConversion.Create();
	DataProcessorObject.WriteToExecutionProtocol(ErrorText);
	
EndProcedure

Procedure PopulateAttributesOfSelectiveRegistrationByOCRCollection(SelectiveRegistrationParameters, ExchangePlanName, ConversionRulesTable)
	
	If ConversionRulesTable.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	RegistrationAttributesTable = SelectiveObjectsRegistrationRulesTableInitialization();
	ResultTable1             = SelectiveObjectsRegistrationRulesTableInitialization();
	
	For Each OCR In ConversionRulesTable Do
		
		FillObjectChangeRecordAttributeTableDetailsByRule(OCR, ResultTable1);
		
	EndDo;
		
	ResultTableGroup = ResultTable1.Copy();
	ResultTableGroup.GroupBy("ObjectName, TabularSectionName");
	
	// Get the resulting table with grouped rows from the preliminary table.
	For Each TableRow In ResultTableGroup Do
		
		Filter = New Structure("ObjectName, TabularSectionName", TableRow.ObjectName, TableRow.TabularSectionName);
		ResultTableRowArray = ResultTable1.FindRows(Filter);
		SupplementChangeRecordAttributeTable(ResultTableRowArray, RegistrationAttributesTable);
		
	EndDo;
	
	DeleteChangeRecordAttributeTableRowsWithErrors(RegistrationAttributesTable);
	CheckObjectChangeRecordAttributes(RegistrationAttributesTable);
	
	// Column "ExchangePlanName" is saved for backward compatibility
	RegistrationAttributesTable.FillValues(ExchangePlanName, "ExchangePlanName");
	
	SelectiveRegistrationParameters.RegistrationAttributesTable = RegistrationAttributesTable;
	
EndProcedure

Procedure FillObjectChangeRecordAttributeTableDetailsByRule(OCR, ResultTable1)
	
	ObjectName        = StrReplace(OCR.SourceType, "Ref", "");
	ObjectTypeString = OCR.SourceType;
	
	// Filling in the table with the header attributes (properties).
	AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, "", -50, OCR.Properties, ResultTable1);
	
	// Filling in the table with the header attributes (search properties).
	AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, "", -50, OCR.SearchProperties, ResultTable1);
	
	// Filling in the table with the header attributes (disabled properties).
	AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, "", -50, OCR.DisabledProperties, ResultTable1);
	
	// Rule tables.
	PGCRArray = OCR.Properties.FindRows(New Structure("IsFolder", True));
	
	For Each PGCR In PGCRArray Do
		
		// Filling in the table with the tabular section attributes.
		AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.GroupRules, ResultTable1);
		
		// Filling in the table with the tabular section attributes (disabled).
		AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.DisabledGroupRules, ResultTable1);
		
	EndDo;
	
	// Rule tabular sections (disabled).
	PGCRArray = OCR.DisabledProperties.FindRows(New Structure("IsFolder", True));
	
	For Each PGCR In PGCRArray Do
		
		// Filling in the table with the tabular section attributes.
		AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.GroupRules, ResultTable1);
		
		// Filling in the table with the tabular section attributes (disabled).
		AddRowToSelectiveRegistrationTable(ObjectTypeString, ObjectName, PGCR.Source, PGCR.Order, PGCR.DisabledGroupRules, ResultTable1);
		
	EndDo;
	
EndProcedure

Procedure FillCommonAttributeTable(CommonAttributeTable)
	
	If Metadata.CommonAttributes.Count() <> 0 Then
		
		CommonAttributeAutoUse = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		CommonAttributeUse = Metadata.ObjectProperties.CommonAttributeUse.Use;
		
		For Each CommonAttribute In Metadata.CommonAttributes Do
			
			If CommonAttribute.DataSeparationUse = Undefined Then
				
				AutoUse = (CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
				
				For Each Item In CommonAttribute.Content Do
					
					If Item.Use = CommonAttributeUse
						Or (Item.Use = CommonAttributeAutoUse And AutoUse) Then
						
						NewRow = CommonAttributeTable.Add();
						NewRow.CommonAttribute = CommonAttribute.Name;
						NewRow.MetadataObject = Item.Metadata.FullName();
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure BeforeGenerateNewParametersOfExchangePlanDataSelectiveRegistration(SelectiveRegistrationParameters, ExchangePlanName)
	
	SetPrivilegedMode(True);
	
	If DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
		
		SelectiveRegistrationParameters.IsXDTOExchangePlan = True;
		
	Else
		
		SelectiveRegistrationParameters.IsXDTOExchangePlan = False;
		
		SelectiveRegistrationMode = DataExchangeRegistrationCached.ExchangePlanDataSelectiveRegistrationMode(ExchangePlanName);
		
		// Bypass the conversion rules and fill the "RegistrationAttributesTable" parameter
		// if the "AccordingToXMLRules" selective registration is set in the exchange plan.
		If SelectiveRegistrationMode = SelectiveRegistrationModeByXMLRules() Then
			
			RulesAreRead = InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangePlanName);
			If TypeOf(RulesAreRead) = Type("ValueStorage") Then
				
				StructureOfReadRules = RulesAreRead.Get();
				If StructureOfReadRules.Property("ConversionRulesTable")
					And TypeOf(StructureOfReadRules.ConversionRulesTable) = Type("ValueTable") Then
					
					PopulateAttributesOfSelectiveRegistrationByOCRCollection(SelectiveRegistrationParameters, ExchangePlanName, StructureOfReadRules.ConversionRulesTable);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteChangeRecordAttributeTableRowsWithErrors(RegistrationAttributesTable)
	
	CollectionItemsCount = RegistrationAttributesTable.Count();
	
	For ReverseIndex = 1 To CollectionItemsCount Do
		
		TableRow = RegistrationAttributesTable[CollectionItemsCount - ReverseIndex];
		
		// If there are no registration attributes, deleting the row.
		If IsBlankString(TableRow.RegistrationAttributes) Then
			
			RegistrationAttributesTable.Delete(TableRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
