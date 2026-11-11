#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region AutomaticCreation

// Adds both the transfer rule and the rule for receiving the specified props with the option of filling
// in "From the consumer object's props".
//
// Parameters:
//   Rule - CatalogObject.RulesForIntegrationWith1CDocumentManagement - link to the integration rule.
//   AttributeNameObjectIS - String - the name of the props of the integrated system object.
//   AttributeNameObjectDM - String - the name of the document flow object's details.
//   FillingRule - See Catalogs.RulesForIntegrationWith1CDocumentManagement.NewRuleForFillingInAttributes
//
Procedure AddPairRule(Rule, AttributeNameObjectIS, AttributeNameObjectDM, FillingRule) Export
	
	FillingRule.FillValue =
		?(FillingRule.TableIS = "", "", FillingRule.TableIS + ".") + AttributeNameObjectIS;
	AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		AttributeNameObjectDM,
		FillingRule);
	
	FillingRule.FillValue =
		?(FillingRule.TableBefore = "", "", FillingRule.TableBefore + ".") + AttributeNameObjectDM;
	AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		AttributeNameObjectIS,
		FillingRule);
	
EndProcedure

// Adds a rule for transferring props to 1C:Document flow from an integrated system.
//
// Parameters:
//   Rule - CatalogObject.RulesForIntegrationWith1CDocumentManagement - link to the integration rule.
//   Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes - option of filling in the props.
//   AttributeNameObjectDM - String - the name of the document flow object's details.
//   FillingRule - See Catalogs.RulesForIntegrationWith1CDocumentManagement.NewRuleForFillingInAttributes
//
Procedure AddAttributeFillingRuleDM(Rule, Variant, AttributeNameObjectDM, FillingRule) Export
	
	Attribute = Rule.AttributeFillingRulesDM.Add();
	Attribute.AttributeNameObjectDM = AttributeNameObjectDM;
	Attribute.Variant = Variant;
	Attribute.KeyAttribute_ = FillingRule.KeyAttribute_;
	Attribute.ShouldUpdate = FillingRule.ShouldUpdateBefore;
	Attribute.Table = FillingRule.TableBefore;
	Attribute.ThisIsTable = (StrFind(AttributeNameObjectDM, ".") > 0);
	
	If Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
		Attribute.ComputedExpression = FillingRule.FillValue;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
		Attribute.AttributeNameObjectIS = FillingRule.FillValue;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue Then
		Attribute.AttributeValueDM = FillingRule.FillValue.name;
		Attribute.AttributeValueDMID = FillingRule.FillValue.objectID.ID;
		Attribute.AttributeValueDMType = FillingRule.FillValue.objectID.type;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.TableAttribute Then
		
	Else
		Raise StrTemplate(
			NStr("vi = 'Không hỗ trợ thêm quy tắc điền mục tin với phương án %1 ở chế độ tự động';
				|ru = 'Добавление правила заполнения реквизита с вариантом %1 в автоматическом режиме не поддерживается';
				|en = 'Adding the rule of filling the account with the option %1 in automatic mode is not supported'; fa = 'Adding the rule of filling the account with the option %1 in automatic mode is not supported';
				|it = 'L''aggiunta della regola di compilazione dell''attributo con la variante %1 in modalità automatica non è supportata';
				|pl = 'Dodawanie reguły wypełnienia atrybutu z wariantem %1 w trybie automatycznym nie jest obsługiwane';
				|tr = 'Otomatik modda %1 seçeneğiyle öznitelik doldurma kuralı eklenmesi desteklenmiyor'"),
			Variant);
		
	EndIf;
	
EndProcedure

// Adds a rule for getting props from 1C:Document flow into an integrated system.
//
// Parameters:
//   Rule - CatalogObject.RulesForIntegrationWith1CDocumentManagement - link to the integration rule.
//   Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes - option of filling in the props.
//   AttributeNameObjectIS - String - the name of the consumer object's props.
//   FillingRule - See Catalogs.RulesForIntegrationWith1CDocumentManagement.NewRuleForFillingInAttributes
//
Procedure AddAttributeFillingRuleIS(Rule, Variant, AttributeNameObjectIS, FillingRule) Export
	
	Attribute = Rule.AttributeFillingRulesIS.Add();
	Attribute.AttributeNameObjectIS = AttributeNameObjectIS;
	Attribute.Variant = Variant;
	Attribute.KeyAttribute_ = FillingRule.KeyAttribute_;
	Attribute.ShouldUpdate = FillingRule.ToUpdate_1IS;
	Attribute.ModeOfChangingTheDataOfThePostedDocument = FillingRule.ChangeMode;
	Attribute.Table = FillingRule.TableIS;
	Attribute.ThisIsTable = False;
	If ValueIsFilled(Rule.ObjectTypeIS) Then
		ObjectMetadata = Metadata.FindByFullName(Rule.ObjectTypeIS);
		Attribute.ThisIsTable = ObjectMetadata <> Undefined
			And ObjectMetadata.TabularSections.Find(AttributeNameObjectIS) <> Undefined;
	EndIf;
	
	If Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
		Attribute.ComputedExpression = FillingRule.FillValue;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
		Attribute.AttributeNameObjectDM = FillingRule.FillValue;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue Then
		Attribute.AttributeValueIS = FillingRule.FillValue;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.TableAttribute Then
		
	Else
		Raise StrTemplate(
			NStr("vi = 'Không hỗ trợ thêm quy tắc điền mục tin với phương án %1 ở chế độ tự động';
				|ru = 'Добавление правила заполнения реквизита с вариантом %1 в автоматическом режиме не поддерживается';
				|en = 'Adding the rule of filling the account with the option %1 in automatic mode is not supported'; fa = 'Adding the rule of filling the account with the option %1 in automatic mode is not supported';
				|it = 'L''aggiunta della regola di compilazione dell''attributo con la variante %1 in modalità automatica non è supportata';
				|pl = 'Dodawanie reguły wypełnienia atrybutu z wariantem %1 w trybie automatycznym nie jest obsługiwane';
				|tr = 'Otomatik modda %1 seçeneğiyle öznitelik doldurma kuralı eklenmesi desteklenmiyor'"),
			Variant);
			
	EndIf;
	
EndProcedure

// Constructor of the structure describing the rule for filling in the request.
//
// Parameters:
//   FillValue - String, XDTODataObject, AnyRef, Undefined - the value of the rule.
//
// Returns:
//   Structure:
//     * FillValue - String, XDTODataObject, AnyRef, Undefined - the value of the rule.
//     * ToUpdate_1IS - Boolean - update the value of the props in the IP object.
//     * ShouldUpdateBefore - Boolean - update the value of the props in the object TO.
//     * KeyAttribute_ - Boolean - key props.
//     * ChangeMode - EnumRef.ModeOfChangingPostedDocumentBy1CDocumentManagementData - the mode
//         of changing the data of the conducted document in the rule for filling in the IP Attributes.
//     * TableIS - String - the name of the IP table to which the props belong.
//     * TableBefore - String - the name of the table TO which the props belong.
//
Function NewRuleForFillingInAttributes(FillValue = Undefined) Export
	
	FillingRule = New Structure;
	FillingRule.Insert("FillValue", FillValue);
	FillingRule.Insert("ToUpdate_1IS", True);
	FillingRule.Insert("ShouldUpdateBefore", True);
	FillingRule.Insert("KeyAttribute_", False);
	FillingRule.Insert("ChangeMode",
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting);
	FillingRule.Insert("TableIS", "");
	FillingRule.Insert("TableBefore", "");
	
	Return FillingRule;
	
EndFunction

#EndRegion

// Returns the document view UP TO from the integration rule data.
//
// Parameters:
//   TheseRules - See Catalogs.RulesForIntegrationWith1CDocumentManagement.TheseRulesForUploading
//
// Returns:
//   Undefined, Structure - document type BEFORE:
//     * ID - String - ID of the document type.
//     * type - String - type of document type.
//     * name - String - name of the document type.
//
Function DocumentViewFromRule(TheseRules) Export
	
	// Let's define the type of document to be filled in and get a description of its details.
	FilterParameters = New Structure;
	FilterParameters.Insert("AttributeNameObjectDM", "documentType");
	FilterParameters.Insert("IsAdditionalAttributeDM", False);
	FilterParameters.Insert("Variant", OptionValue_());
	
	// The document type can be set explicitly and overlap the template.
	LinesDocumentView = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters); // Array of See Catalogs.RulesForIntegrationWith1CDocumentManagement.
	DocumentKind = Undefined;
	If LinesDocumentView.Count() > 0 Then
		String = LinesDocumentView[0];
		DocumentKind = New Structure;
		DocumentKind.Insert("ID", String.AttributeValueDMID);
		DocumentKind.Insert("type", String.AttributeValueDMType);
		DocumentKind.Insert("name", String(String.AttributeValueDM));
		
	Else // The document type can be set only in the template.
		FilterParameters.Variant = OptionTemplate();
		
		LinesDocumentView = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters); // Array of See Catalogs.RulesForIntegrationWith1CDocumentManagement.
		If LinesDocumentView.Count() > 0 Then
			String = LinesDocumentView[0];
			DocumentKind = New Structure;
			DocumentKind.Insert("ID", String.TemplateID);
			DocumentKind.Insert("type", String.TemplateType);
			DocumentKind.Insert("name", String(String.TemplateMeaning));
		EndIf;
		
	EndIf;
	
	Return DocumentKind;
	
EndFunction

// Returns a table of possible Workflow document states.
//
// Returns:
//   ValueTable:
//     * Name - String
//     * Presentation - String
//     * Type - ValueList of String
//     * AdditionalAttribute5 - Boolean
//     * AdditionalAttribute5ID - String
//     * AdditionalAttribute5Type - String
//     * Mandatory - Boolean
//
Function PossibleStatesOfThe1CDocumentManagementObject() Export
	
	Attributes = New ValueTable;
	Attributes.Columns.Add("Name");
	Attributes.Columns.Add("Presentation");
	Attributes.Columns.Add("Type");
	Attributes.Columns.Add("AdditionalAttribute5");
	Attributes.Columns.Add("AdditionalAttribute5ID");
	Attributes.Columns.Add("AdditionalAttribute5Type");
	Attributes.Columns.Add("Mandatory");
	
	AddAttribute(Attributes, "statusRegistration", NStr("vi = 'Trạng thái đăng ký';
														|ru = 'Состояние регистрации';
														|en = 'Registration state'; fa = 'Registration state';
														|it = 'Stato registrazione';
														|pl = 'Status rejestracji';
														|tr = 'Kayıt durumu'"), "DMDocumentStatus");
	AddAttribute(Attributes, "statusConsideration", NStr("vi = 'Trạng thái xem xét';
														|ru = 'Состояние рассмотрения';
														|en = 'Review state'; fa = 'Review state';
														|it = 'Stato valutazione';
														|pl = 'Status rozpatrzenia';
														|tr = 'Değerlendirme durumu'"), "DMDocumentStatus");
	AddAttribute(Attributes, "statusApproval", NStr("vi = 'Trạng thái thống nhất';
													|ru = 'Состояние согласования';
													|en = 'Approval state '; fa = 'وضعیت تأیید';
													|it = 'Stato omologazione';
													|pl = 'Status uzgodnienia';
													|tr = 'Onay durumu'"), "DMDocumentStatus");
	AddAttribute(Attributes, "statusConfirmation", NStr("vi = 'Trạng thái phê duyệt';
														|ru = 'Состояние утверждения';
														|en = 'Confirmation state'; fa = 'Confirmation state';
														|it = 'Stato conferma';
														|pl = 'Status zatwierdzenia';
														|tr = 'Onay durumu'"), "DMDocumentStatus");
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		AddAttribute(Attributes, "statusSigning", NStr("vi = 'Trạng thái ký';
														|ru = 'Состояние подписания';
														|en = 'Signature state'; fa = 'وضعیت امضا';
														|it = 'Stato firma';
														|pl = 'Status podpisania';
														|tr = 'İmza durumu'"), "DMDocumentStatus");
	EndIf;
	AddAttribute(Attributes, "statusPerformance", NStr("vi = 'Trạng thái thực hiện';
														|ru = 'Состояние исполнения';
														|en = 'Execution state'; fa = 'Execution state';
														|it = 'Stato esecuzione';
														|pl = 'Status wykonania';
														|tr = 'Yürütme durumu'"), "DMDocumentStatus");
	
	Return Attributes;
	
EndFunction

// Retrieves these rules for uploading.
//
// Parameters:
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule whose data you need to get.
//
// Returns:
//   Structure - these are the rules required for uploading, the keys are the names of Attributes and table parts:
//     * AttributeFillingRulesDM - See Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM
//     * AttachedPrintedForms - See Catalog.RulesForIntegrationWith1CDocumentManagement.AttachedPrintedForms
//
Function TheseRulesForUploading(Rule) Export
	
	Query = New Query(
		"SELECT
		|	Rule.Ref AS Ref,
		|	Rule.ObjectTypeIS AS ObjectTypeIS,
		|	Rule.ObjectTypeDM AS ObjectTypeDM,
		|	Rule.TypeOfSavedPrintedFormFile AS TypeOfSavedPrintedFormFile,
		|	Rule.Template AS Template,
		|	Rule.TemplateType AS TemplateType,
		|	Rule.TemplateID AS TemplateID,
		|	Rule.TemplateForbidModification AS TemplateForbidModification,
		|	Rule.DoNotCreateRelationsByLinks AS DoNotCreateRelationsByLinks,
		|	Rule.AttributeFillingRulesDM.(
		|		AttributeFillingRulesDM.LineNumber AS LineNumber,
		|		AttributeFillingRulesDM.Variant AS Variant,
		|		AttributeFillingRulesDM.ComputedExpression AS ComputedExpression,
		|		AttributeFillingRulesDM.IsAdditionalAttributeDM AS IsAdditionalAttributeDM,
		|		AttributeFillingRulesDM.AdditionalAttributeDMID AS AdditionalAttributeDMID,
		|		AttributeFillingRulesDM.AdditionalAttributeDMType AS AdditionalAttributeDMType,
		|		AttributeFillingRulesDM.IsAdditionalAttributeIS AS IsAdditionalAttributeIS,
		|		AttributeFillingRulesDM.AdditionalAttributeIS AS AdditionalAttributeIS,
		|		AttributeFillingRulesDM.FilledInTemplate AS FilledInTemplate,
		|		AttributeFillingRulesDM.AttributeValueDM AS AttributeValueDM,
		|		AttributeFillingRulesDM.AttributeValueDMID AS AttributeValueDMID,
		|		AttributeFillingRulesDM.AttributeNameObjectDM AS AttributeNameObjectDM,
		|		AttributeFillingRulesDM.AttributeNameObjectIS AS AttributeNameObjectIS,
		|		AttributeFillingRulesDM.KeyAttribute_ AS KeyAttribute_,
		|		AttributeFillingRulesDM.Table AS Table,
		|		AttributeFillingRulesDM.ShouldUpdate AS ShouldUpdate,
		|		AttributeFillingRulesDM.AttributeValueDMType AS AttributeValueDMType,
		|		AttributeFillingRulesDM.TemplateMeaning AS TemplateMeaning,
		|		AttributeFillingRulesDM.TemplateID AS TemplateID,
		|		AttributeFillingRulesDM.TemplateType AS TemplateType,
		|		AttributeFillingRulesDM.ThisIsTable AS ThisIsTable
		|	) AS AttributeFillingRulesDM,
		|	Rule.AttachedPrintedForms.(
		|		AttachedPrintedForms.CommandName AS CommandName,
		|		AttachedPrintedForms.PrintManager AS PrintManager,
		|		AttachedPrintedForms.AdditionalParameters AS AdditionalParameters,
		|		AttachedPrintedForms.ShouldUpdate AS ShouldUpdate,
		|		AttachedPrintedForms.CommandPresentation AS CommandPresentation
		|	) AS AttachedPrintedForms
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rule
		|WHERE
		|	Rule.Ref = &Rule
		|
		|ORDER BY
		|	LineNumber");
		
	Query.SetParameter("Rule", Rule);
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	TheseRules = New Structure;
	For Each Column In Result.Columns Do
		TheseRules.Insert(Column.Name, Selection[Column.Name]);
	EndDo;
	TheseRules.AttributeFillingRulesDM = TheseRules.AttributeFillingRulesDM.Unload();
	TheseRules.AttachedPrintedForms = TheseRules.AttachedPrintedForms.Unload();
	
	Return TheseRules;
	
EndFunction

// Fills in the IC object by the XDTO object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Object - Arbitrary - the object to fill in.
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement - rules for filling in.
//   RefreshEnabled - Boolean - fill in only Attributes with Update = True.
//   RequiresRecheck - Boolean - True if the change requires rechecking.
//
// Returns:
//   Boolean - True if the object has been modified, and False otherwise.
//
Function FillInObjectByXDTOObject(Proxy, Object, XDTODataObject, Rule,
		RefreshEnabled = False, RequiresRecheck = False) Export
	
	ObjectModified = False;
	UpdatedTableParts = New Map;
	
	ObjectMetadata = Object.Metadata();
	Attributes = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(ObjectMetadata.FullName());
	
	CheckingForCrossChecking = RefreshEnabled
		And Common.IsDocument(ObjectMetadata)
		And ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow
		And Object.Posted;
	Prohibited =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
	AllowedWithoutReposting =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	AllowedWithReposting =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	IsRequestForPayment = False;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "documentType")
			And IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject.documentType, "isAPaymentRequest")
			And XDTODataObject.documentType.isAPaymentRequest = True Then
		IsRequestForPayment = True;
	EndIf;
	
	// The redefined module can override the rule settings, allowing the change without rechecking.
	UpdatedBankingDetails = New Array;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingUpdatedDetailsOfConductedDocument(
		ObjectMetadata.FullName(),
		UpdatedBankingDetails);
	
	AttributeFillingRulesIS = Common.ObjectAttributeValue(
		Rule,
		"AttributeFillingRulesIS").Unload();
	
	For Each Attribute In Attributes Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("AttributeNameObjectIS", Attribute.Name);
		FilterParameters.Insert("ThisIsTable", Attribute.ThisIsTable);
		FilterParameters.Insert("Table", Attribute.Table);
		If RefreshEnabled Then
			FilterParameters.Insert("ShouldUpdate", True);
		EndIf;
		
		FoundRulesForBankingDetails = AttributeFillingRulesIS.FindRows(FilterParameters);
		If FoundRulesForBankingDetails.Count() = 0 Then
			Continue;
		EndIf;
		PropsRule = FoundRulesForBankingDetails[0];
		
		If CheckingForCrossChecking Then
			If PropsRule.ModeOfChangingTheDataOfThePostedDocument = AllowedWithReposting Then
				ChangeMode = AllowedWithReposting;
			ElsIf PropsRule.ModeOfChangingTheDataOfThePostedDocument = AllowedWithoutReposting
					Or UpdatedBankingDetails.Find(Attribute.Name) <> Undefined Then
				ChangeMode = AllowedWithoutReposting;
			Else
				ChangeMode = Prohibited;
			EndIf;
		Else
			ChangeMode = AllowedWithoutReposting;
		EndIf;
		
		If Attribute.ThisIsTable Then
			
			UpdatedTableParts.Insert(Attribute.Name, Object[Attribute.Name].Unload());
			Object[Attribute.Name].Clear();
			
			If PropsRule.Variant = OptionProps() Then // Fill it with empty lines.
				
				SplitRow = StrSplit(PropsRule.AttributeNameObjectDM, ".", False);
				If SplitRow.Count() = 1 Then
					XDTOList = XDTODataObject[SplitRow[0]];
				Else
					XDTOList = XDTODataObject[SplitRow[0]][SplitRow[1]];
				EndIf;
				
				For Each XDTOListItem In XDTOList Do
					Object[Attribute.Name].Add();
				EndDo;
				
			ElsIf PropsRule.Variant = TablePropsOption() Then // Add a single line.
				
				Object[Attribute.Name].Add();
				
			ElsIf PropsRule.Variant = VariantExpression() Then // We'll load it from the result table.
				
				Parameters = New Structure;
				Parameters.Insert("Source", XDTODataObject);
				Parameters.Insert("Receiver", Object);
				Parameters.Insert("Result", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				If TypeOf(Parameters.Result) = Type("ValueTable") Then
					Object[Attribute.Name].Load(Parameters.Result);
				EndIf;
				
			Else // The values specified for the Attributes: add a single line.
				
				Object[Attribute.Name].Add();
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		If Not Attribute.IsAdditionalAttributeIS Then
			
			// From the object's props TO.
			If PropsRule.Variant = OptionProps() Then
				
				PropertyValues_ = New Array;
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					
					SplitRow = StrSplit(PropsRule.AttributeNameObjectDM, ".", False);
					If SplitRow.Count() = 1 Then // "property"
						PropertyName = PropsRule.AttributeNameObjectDM;
						If IsRequestForPayment And PropertyName = "recipient" Then
							PropertyValues_.Add(ApplicationPartyForXDTOPayment(XDTODataObject, "Получатель")); //@NON-NLS-1
						ElsIf TypeOf(XDTODataObject[PropertyName]) = Type("XDTOList") Then
							For Each XDTOListItem In XDTODataObject[PropertyName] Do
								PropertyValues_.Add(XDTOListItem);
							EndDo;
						Else
							PropertyValues_.Add(XDTODataObject[PropertyName]);
						EndIf;
					ElsIf SplitRow.Count() = 2 Then // "the list.property"
						XDTOList = XDTODataObject[SplitRow[0]];
						PropertyName = SplitRow[1];
						For Each XDTOListItem In XDTOList Do
							PropertyValues_.Add(XDTOListItem[PropertyName]);
						EndDo;
					ElsIf SplitRow.Count() = 3 Then // "the list.list.property"
						XDTOList = XDTODataObject[SplitRow[0]][SplitRow[1]];
						PropertyName = SplitRow[2];
						For Each XDTOListItem In XDTOList Do
							PropertyValues_.Add(XDTOListItem[PropertyName]);
						EndDo;
					Else
						Raise StrTemplate(
							NStr("vi = 'Trong quy tắc tích hợp đã chỉ ra tên mục tin nguồn dữ liệu điền không hợp lệ: %1';
								|ru = 'В правилах интеграции указано недопустимое имя реквизита-источника данных заполнения: %1';
								|en = 'Integration rules specify an invalid data source attribute name: %1'; fa = 'Integration rules specify an invalid data source attribute name: %1';
								|it = 'Nelle regole di integrazione è indicato un nome non disponibile dell''attributo-fonte dei dati di compilazione: %1';
								|pl = 'W regułach integracji podano niedopuszczalną nazwę atrybutu-źródła danych wypełnienia: %1';
								|tr = 'Entegrasyon kurallarında, doldurma verilerinin öznitelik kaynağının geçersiz adı belirtildi: %1'"),
							PropsRule.AttributeNameObjectDM);
					EndIf;
					
				Else // Additional Attributes TO.
					
					For Each String In XDTODataObject.additionalProperties Do
						If String.objectID.ID = PropsRule.AdditionalAttributeDMID
							And String.objectID.type = PropsRule.AdditionalAttributeDMType Then
							If String.propertySimpleValue <> Undefined Then
								PropertyValues_.Add(String.propertySimpleValue);
							ElsIf String.propertyObjectValue <> Undefined Then
								PropertyValues_.Add(String.propertyObjectValue);
							Else
								PropertyValue = Undefined;
							EndIf;
						EndIf;
					EndDo;
					
				EndIf;
				
				For ValueNumber = 0 To PropertyValues_.Count() - 1 Do
					
					PropertyValue = PropertyValues_[ValueNumber];
					AttributeValue = Undefined;
					
					AttributeType = IntegrationWith1CDocumentManagementCore.SuitableType(
						Attribute.Type.Types(),
						PropertyValue);
					
					IsPrimitiveType = AttributeType = Type("String")
						Or AttributeType = Type("Date")
						Or AttributeType = Type("Number")
						Or AttributeType = Type("Boolean");
					ThisIsObjectValue =
						IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(Proxy, PropertyValue);
					
					If IsPrimitiveType And Not ThisIsObjectValue Then
						
						AttributeValue = PropertyValue;
						
					ElsIf PropertyValue <> Undefined And ThisIsObjectValue Then
						
						ChoiceParameters = New Map;
						For Each RelationshipOfSelectionParameters In Attribute.ChoiceParameterLinks Do
							SplitPath = StrSplit(RelationshipOfSelectionParameters.DataPath, ".");
							If SplitPath.Count() = 2
								And SplitPath[0] = Attribute.Table Then
								While Object[Attribute.Table].Count() - 1 < ValueNumber Do
									Object[Attribute.Table].Add();
								EndDo;
								String = Object[Attribute.Table][ValueNumber];
								ChoiceParameters[RelationshipOfSelectionParameters.Name] = String[SplitPath[1]];
							ElsIf SplitPath.Count() = 1 Then
								ChoiceParameters[RelationshipOfSelectionParameters.Name] = Object[SplitPath[0]];
							Else
								Continue; // other data path options are not supported
							EndIf;
						EndDo;
						
						Context = IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject();
						Context.ObjectToFillInIS = Object;
						Context.AttributeNameObjectIS = Attribute.Name;
						Context.ChoiceParameters = ChoiceParameters;
						AttributeValue =
							IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
								AttributeType,
								IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(PropertyValue),
								Context);
						
					EndIf;
					
					If ValueIsFilled(Attribute.Table) Then // Attributes of the table part.
						
						While Object[Attribute.Table].Count() - 1 < ValueNumber Do
							Object[Attribute.Table].Add();
						EndDo;
						String = Object[Attribute.Table][ValueNumber];
						OldTable = UpdatedTableParts[Attribute.Table];
						If ValueNumber < OldTable.Count() Then
							PreviousValue = OldTable[ValueNumber][Attribute.Name];
						Else
							PreviousValue = Undefined;
						EndIf;
						String[Attribute.Name] = AttributeValue;
						If String[Attribute.Name] <> PreviousValue Then
							If ChangeMode = Prohibited Then
								String[Attribute.Name] = PreviousValue;
							ElsIf ChangeMode = AllowedWithoutReposting Then
								ObjectModified = True;
							ElsIf ChangeMode = AllowedWithReposting Then
								ObjectModified = True;
								RequiresRecheck = True;
							EndIf;
						EndIf;
						
					Else // Cap Attributes.
						
						If AttributeValue <> Undefined Then
							
							PreviousValue = Object[Attribute.Name];
							Object[Attribute.Name] = AttributeValue;
							If Object[Attribute.Name] <> PreviousValue Then
								If ChangeMode = Prohibited Then
									Object[Attribute.Name] = PreviousValue;
								ElsIf ChangeMode = AllowedWithoutReposting Then
									ObjectModified = True;
								ElsIf ChangeMode = AllowedWithReposting Then
									ObjectModified = True;
									RequiresRecheck = True;
								EndIf;
							EndIf;
							
						EndIf;
						
						Break; // When filling in the Attributes in the table, the first row is used.
						
					EndIf;
					
				EndDo;
				
			// From the specified value.
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				AttributeValue = PropsRule.AttributeValueIS;
				
				If ValueIsFilled(Attribute.Table) Then // Attributes of the table part.
					
					OldTable = UpdatedTableParts[Attribute.Table];
					Number = 0;
					For Each String In Object[Attribute.Table] Do
						
						If Number < OldTable.Count() Then
							PreviousValue = OldTable[Number][Attribute.Name];
						Else
							PreviousValue = Undefined;
						EndIf;
						String[Attribute.Name] = AttributeValue;
						If String[Attribute.Name] <> PreviousValue Then
							If ChangeMode = Prohibited Then
								String[Attribute.Name] = PreviousValue;
							ElsIf ChangeMode = AllowedWithoutReposting Then
								ObjectModified = True;
							ElsIf ChangeMode = AllowedWithReposting Then
								ObjectModified = True;
								RequiresRecheck = True;
							EndIf;
						EndIf;
						Number = Number + 1;
						
					EndDo;
					
				Else // Cap Attributes.
					
					PreviousValue = Object[Attribute.Name];
					Object[Attribute.Name] = AttributeValue;
					If Object[Attribute.Name] <> PreviousValue Then
						If ChangeMode = Prohibited Then
							Object[Attribute.Name] = PreviousValue;
						ElsIf ChangeMode = AllowedWithoutReposting Then
							ObjectModified = True;
						ElsIf ChangeMode = AllowedWithReposting Then
							ObjectModified = True;
							RequiresRecheck = True;
						EndIf;
					EndIf;
					
				EndIf;
				
			// From an expression in the embedded language.
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", XDTODataObject);
				Parameters.Insert("Receiver", Object);
				Parameters.Insert("Result", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				If Parameters.Result <> Undefined Then
					
					If ValueIsFilled(Attribute.Table) Then // Attributes of the table part.
						
						OldTable = UpdatedTableParts[Attribute.Table];
						Number = 0;
						For Each String In Object[Attribute.Table] Do
							
							If Number < OldTable.Count() Then
								PreviousValue = OldTable[Number][Attribute.Name];
							Else
								PreviousValue = Undefined;
							EndIf;
							FillInResultOfExpressionInBuiltInLanguage(
								String,
								Attribute.Name,
								Parameters.Result);
							If String[Attribute.Name] <> PreviousValue Then
								If ChangeMode = Prohibited Then
									String[Attribute.Name] = PreviousValue;
								ElsIf ChangeMode = AllowedWithoutReposting Then
									ObjectModified = True;
								ElsIf ChangeMode = AllowedWithReposting Then
									ObjectModified = True;
									RequiresRecheck = True;
								EndIf;
							EndIf;
							Number = Number + 1;
							
						EndDo;
						
					Else // Cap Attributes.
						
						PreviousValue = Object[Attribute.Name];
						FillInResultOfExpressionInBuiltInLanguage(
							Object,
							Attribute.Name,
							Parameters.Result);
						If Object[Attribute.Name] <> PreviousValue Then
							If ChangeMode = Prohibited Then
								Object[Attribute.Name] = PreviousValue;
							ElsIf ChangeMode = AllowedWithoutReposting Then
								ObjectModified = True;
							ElsIf ChangeMode = AllowedWithReposting Then
								ObjectModified = True;
								RequiresRecheck = True;
							EndIf;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		Else // Additional Attributes of the IP object.
			
			TheStructureOfTheSearch = New Structure("Property", Attribute.AdditionalAttributeIS);
			StringsOfProps = Object.AdditionalAttributes.FindRows(TheStructureOfTheSearch);
			If StringsOfProps.Count() = 0 Then
				ObjectModified = True;
				PropsString = Object.AdditionalAttributes.Add();
				PropsString.Property = Attribute.AdditionalAttributeIS;
			Else
				PropsString = StringsOfProps[0];
			EndIf;
			
			If PropsRule.Variant = OptionProps() Then
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					
					SplitRow = StrSplit(PropsRule.AttributeNameObjectDM, ".", False);
					If SplitRow.Count() = 1 Then
						PropertyName = PropsRule.AttributeNameObjectDM;
						If IsRequestForPayment And PropertyName = "recipient" Then
							PropertyValues_.Add(ApplicationPartyForXDTOPayment(XDTODataObject, "Получатель")); //@NON-NLS-1
						ElsIf TypeOf(XDTODataObject[PropertyName]) = Type("XDTOList") Then
							For Each XDTOListItem In XDTODataObject[PropertyName] Do
								PropertyValue = XDTOListItem;
								Break;
							EndDo;
						Else
							PropertyValue = XDTODataObject[PropertyName];
						EndIf;
					ElsIf SplitRow.Count() = 2 Then // "the list.property"
						XDTOList = XDTODataObject[SplitRow[0]];
						PropertyName = SplitRow[1];
						For Each XDTOListItem In XDTOList Do
							PropertyValue = XDTOListItem[PropertyName];
							Break;
						EndDo;
					ElsIf SplitRow.Count() = 3 Then // "the list.list.property"
						XDTOList = XDTODataObject[SplitRow[0]][SplitRow[1]];
						PropertyName = SplitRow[2];
						For Each XDTOListItem In XDTOList Do
							PropertyValue = XDTOListItem[PropertyName];
							Break;
						EndDo;
					Else
						Raise StrTemplate(
							NStr("vi = 'Trong quy tắc tích hợp đã chỉ ra tên mục tin nguồn dữ liệu điền không hợp lệ: %1';
								|ru = 'В правилах интеграции указано недопустимое имя реквизита-источника данных заполнения: %1';
								|en = 'Integration rules specify an invalid data source attribute name: %1'; fa = 'Integration rules specify an invalid data source attribute name: %1';
								|it = 'Nelle regole di integrazione è indicato un nome non disponibile dell''attributo-fonte dei dati di compilazione: %1';
								|pl = 'W regułach integracji podano niedopuszczalną nazwę atrybutu-źródła danych wypełnienia: %1';
								|tr = 'Entegrasyon kurallarında, doldurma verilerinin öznitelik kaynağının geçersiz adı belirtildi: %1'"),
							PropsRule.AttributeNameObjectDM);
					EndIf;
					
				Else // Additional Attributes TO.
					
					For Each String In XDTODataObject.additionalProperties Do
						If String.objectID.ID = PropsRule.AdditionalAttributeDMID
								And String.objectID.type = PropsRule.AdditionalAttributeDMType Then
							If String.propertySimpleValue <> Undefined Then
								PropertyValue = String.propertySimpleValue;
							ElsIf  String.propertyObjectValue <> Undefined Then
								PropertyValue = String.propertyObjectValue;
							Else
								PropertyValue = Undefined;
							EndIf;
						EndIf;
					EndDo;
					
				EndIf;
				
				AttributeType = IntegrationWith1CDocumentManagementCore.SuitableType(
					Attribute.Type.Types(),
					PropertyValue);
				
				IsPrimitiveType = AttributeType = Type("String")
					Or AttributeType = Type("Date")
					Or AttributeType = Type("Number")
					Or AttributeType = Type("Boolean");
				
				ThisIsObjectValue = IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(
					Proxy,
					PropertyValue);
				
				If IsPrimitiveType And Not ThisIsObjectValue Then
					
					PreviousValue = PropsString.Value;
					PropsString.Value = PropertyValue;
					ObjectModified = (ObjectModified Or (PropsString.Value <> PreviousValue));
					
				ElsIf PropertyValue <> Undefined And ThisIsObjectValue Then
					
					Context = IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject();
					Context.ObjectToFillInIS = Object;
					Context.AttributeNameObjectIS = Attribute.Name;
					Context.IsAdditionalAttributeIS = True;
					Context.AdditionalAttributeIS = PropsString.Property;
					ValueToFillIn =
						IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(PropertyValue);
					ValueToFillIn.Owner = PropsString.Property;
					AttributeValue =
						IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
							AttributeType,
							ValueToFillIn,
							Context);
					If AttributeValue <> Undefined Then
						PreviousValue = PropsString.Value;
						PropsString.Value = AttributeValue;
						ObjectModified = (ObjectModified Or (PropsString.Value <> PreviousValue));
					EndIf;
					
				ElsIf Common.IsReference(AttributeType) And TypeOf(PropertyValue) = Type("String") Then
					
					MetadataOfPropsType = Metadata.FindByType(AttributeType);
					If MetadataOfPropsType = Undefined Then
						FullNameOfAttributeType = "";
					Else
						FullNameOfAttributeType = MetadataOfPropsType.FullName();
					EndIf;
					If StrFind(FullNameOfAttributeType, "Catalog.") > 0 Then
						Manager = Common.ObjectManagerByFullName(FullNameOfAttributeType);
						Ref = IntegrationWith1CDocumentManagementCore.FindByDescription(
							Manager, PropertyValue, True);
						If ValueIsFilled(Ref) Then
							PreviousValue = PropsString.Value;
							PropsString.Value = Ref;
							ObjectModified = (ObjectModified Or (PropsString.Value <> PreviousValue));
						EndIf;
					EndIf;
					
				EndIf;
				
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				If PropsString.Value <> PropsRule.AttributeValueIS Then
					ObjectModified = True;
					PropsString.Value = PropsRule.AttributeValueIS;
				EndIf;
				
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", XDTODataObject);
				Parameters.Insert("Receiver", Object);
				Parameters.Insert("Result", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				If Parameters.Result <> Undefined Then
					PreviousValue = PropsString.Value;
					PropsString.Value = Parameters.Result;
					ObjectModified = (ObjectModified Or (PropsString.Value <> PreviousValue));
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each TabularSection In UpdatedTableParts Do
		ObjectModified = (ObjectModified
			Or (ValueToStringInternal(TabularSection.Value) <>
				ValueToStringInternal(Object[TabularSection.Key].Unload())));
	EndDo;
	
	Return ObjectModified;
	
EndFunction

// Fills in the structure of the object's details UP to the IP object and the specified rule.
//
// Parameters:
//   Source - AnyRef - a reference to the original IP object.
//   AttributesStructure1 - Structure - the structure of Attributes previously prepared according to the data of the IP object:
//     * Properties - ValueTable:
//       ** AvailableTypeList - ValueList of Structure:
//         *** xdtoClassName - String
//         *** presentation - String
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement, Structure - the applicable rule.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//   UpdateOnly - Boolean - True if you need to fill in only the automatically updated.
//   DoNotUpdateAccordingToRules - Array of String - the implicitly returned value contains the names of the details of the object BEFORE,
//     which are not specified in the integration rules, or for which the "Update" flag is not set in the rules.
//
Procedure FillInMapItemDetailsStructureUsingRule(Source, AttributesStructure1, Rule,
		ControlOverSendingFiles, UpdateOnly = False, DoNotUpdateAccordingToRules = Undefined) Export
	
	If TypeOf(Rule) = Type("CatalogRef.RulesForIntegrationWith1CDocumentManagement") Then
		TheseRules = TheseRulesForUploading(Rule);
	Else
		TheseRules = Rule;
	EndIf;
	
	// Let's define the type of document to be filled in and get a description of its details.
	FilterParameters = New Structure;
	FilterParameters.Insert("AttributeNameObjectDM", "documentType");
	FilterParameters.Insert("IsAdditionalAttributeDM", False);
	FilterParameters.Insert("Variant", OptionValue_());
	
	// The document type can be set explicitly and overlap the template.
	LinesDocumentView = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters);
	If LinesDocumentView.Count() > 0 Then
		
		LineDocumentView = LinesDocumentView[0];
		
		FillParameters = New Structure;
		FillParameters.Insert("documentType",
			New Structure("ID, type, name",
			LineDocumentView.AttributeValueDMID,
			LineDocumentView.AttributeValueDMType,
			LineDocumentView.AttributeValueDM));
		
	Else // The document type can be set in the template.
		
		FilterParameters.Variant = OptionTemplate();
		LinesDocumentView = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters);
		If LinesDocumentView.Count() > 0 Then
			
			LineDocumentView = LinesDocumentView[0];
			
			FillParameters = New Structure;
			FillParameters.Insert("documentType",
				New Structure("ID, type, name",
				LineDocumentView.TemplateID,
				LineDocumentView.TemplateType,
				LineDocumentView.TemplateMeaning));
			
		EndIf;
		
	EndIf;
	
	Settings_View = Undefined;
	
	ObjectAttributesBefore = ObjectAttributesBefore(
		TheseRules.ObjectTypeDM,
		FillParameters,
		Settings_View);
	
	MatchingXDTPropertiesAndProps =
		MatchingXDTPropertiesAndObjectFormDetailsTo(TheseRules.ObjectTypeDM);
	SourceObject_ = Source.GetObject();
	SourceMetadata = Source.Metadata();
	
	IsRequestForPayment = False;
	If Settings_View <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertyExists(Settings_View, "isAPaymentRequest")
			And Settings_View.isAPaymentRequest = True Then
		IsRequestForPayment = True;
	EndIf;
	If IsRequestForPayment Then
		MatchingXDTPropertiesAndProps.Insert("recipient", "Recipient");
	EndIf;
	
	For Each ObjectAttributeBefore In ObjectAttributesBefore Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("IsAdditionalAttributeDM", ObjectAttributeBefore.AdditionalAttribute5);
		If ObjectAttributeBefore.AdditionalAttribute5 Then
			FilterParameters.Insert("AdditionalAttributeDMID", ObjectAttributeBefore.AdditionalAttribute5ID);
			FilterParameters.Insert("AdditionalAttributeDMType", ObjectAttributeBefore.AdditionalAttribute5Type);
			FilterParameters.Insert("ThisIsTable", False);
			FilterParameters.Insert("Table", "");
		Else
			FilterParameters.Insert("AttributeNameObjectDM", ObjectAttributeBefore.Name);
			FilterParameters.Insert("ThisIsTable", ObjectAttributeBefore.ThisIsTable);
			FilterParameters.Insert("Table", ObjectAttributeBefore.Table);
		EndIf;
		If UpdateOnly Then
			FilterParameters.Insert("ShouldUpdate", True);
		EndIf;
		
		FoundRulesForBankingDetails = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters);
		If FoundRulesForBankingDetails.Count() = 0 Then
			If ObjectAttributeBefore.Table = ""
					And Not ObjectAttributeBefore.AdditionalAttribute5
					And TypeOf(DoNotUpdateAccordingToRules) = Type("Array") Then
				If ObjectAttributeBefore.ThisIsTable Then
					TagName = Left(ObjectAttributeBefore.Name, StrFind(ObjectAttributeBefore.Name, ".") - 1);
				Else
					TagName = ObjectAttributeBefore.Name;
				EndIf;
				DoNotUpdateAccordingToRules.Add(TagName);
			EndIf;
			Continue;
		EndIf;
		PropsRule = FoundRulesForBankingDetails[0]; // CatalogTabularSectionRow.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM
		
		If Not ObjectAttributeBefore.AdditionalAttribute5 Then
			
			If ValueIsFilled(ObjectAttributeBefore.Table) Then
				SplitRow = StrSplit(ObjectAttributeBefore.Table, ".", False);
				OwnerProperty = MatchingXDTPropertiesAndProps[SplitRow[0]];
				TableDetails = OwnerProperty[SplitRow[1]];
				TableName = TableDetails[0];
				AttributeName = TableDetails[1][ObjectAttributeBefore.Name];
			ElsIf ObjectAttributeBefore.ThisIsTable Then
				SplitRow = StrSplit(ObjectAttributeBefore.Name, ".", False);
				OwnerProperty = MatchingXDTPropertiesAndProps[SplitRow[0]];
				TableDetails = OwnerProperty[SplitRow[1]];
				TableName = TableDetails[0];
				AttributeName = "";
			Else
				TableName = "";
				AttributeName = MatchingXDTPropertiesAndProps[ObjectAttributeBefore.Name];
			EndIf;
			
			If ObjectAttributeBefore.ThisIsTable Then
				
				AttributesStructure1[TableName].Clear();
				
				If PropsRule.Variant = OptionProps() Then // Fill it with empty lines.
					
					TabularSection = SourceObject_[PropsRule.AttributeNameObjectIS];
					For Counter = 1 To TabularSection.Count() Do
						AttributesStructure1[TableName].Add();
					EndDo;
					
				ElsIf PropsRule.Variant = TablePropsOption() Then // Add a single line.
					
					AttributesStructure1[TableName].Add();
					
				ElsIf PropsRule.Variant = VariantExpression() Then // We'll load it from the result table.
					
					Parameters = New Structure;
					Parameters.Insert("Source", SourceObject_);
					Parameters.Insert("Result", Undefined);
					
					IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
						PropsRule.ComputedExpression,
						Parameters);
					
					If TypeOf(Parameters.Result) = Type("ValueTable") Then
						
						TableColumns1 = Parameters.Result.Columns; // ValueTableColumnCollection
						
						For Each ResultString1 In Parameters.Result Do
							Table = AttributesStructure1[TableName]; // ValueTable
							Item = Table.Add();
							For Each ResultColumn In TableColumns1 Do
								If Table.Columns.Find(ResultColumn.Name) = Undefined Then
									Continue;
								EndIf;
								PropertyValue = ResultString1[ResultColumn.Name];
								Item[ResultColumn.Name] = PropertyValue;
								IsReferenceType =
									Table.Columns.Find(ResultColumn.Name + "ID") <> Undefined
									And Table.Columns.Find(ResultColumn.Name + "Type") <> Undefined;
								If IsReferenceType Then
									If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(PropertyValue) Then
										Item[ResultColumn.Name + "ID"] = String(PropertyValue.UUID());
										Item[ResultColumn.Name + "Type"] = PropertyValue.Metadata().FullName();
									ElsIf IsEnum(PropertyValue) Then
										If Common.RefExists(PropertyValue) Then
											Item[ResultColumn.Name + "ID"] = Common.EnumerationValueName(PropertyValue);
										EndIf;
										Item[ResultColumn.Name + "Type"] = PropertyValue.Metadata().FullName();
									Else
										Item[ResultColumn.Name + "ID"] = String(PropertyValue);
										Item[ResultColumn.Name + "Type"] = "String";
									EndIf;
								EndIf;
							EndDo;
						EndDo;
						
					EndIf;
					
				Else // The values specified for the Attributes: add a single line.
					
					AttributesStructure1[TableName].Add();
					
				EndIf;
				
				Continue;
				
			EndIf; // This is a table.
			
			AttributeTypeBefore = ObjectAttributeBefore.Type[0].Value;
			
			If PropsRule.Variant = OptionProps() Then
				
				AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
				
				If ValueIsFilled(PropsRule.Table) Then // Attributes of the table part.
					
					SplitRow = StrSplit(AttributeNameObjectIS, ".");
					If SplitRow.Count() = 2 Then
						TabularSection = SourceObject_[SplitRow[0]];
						Values = TabularSection.UnloadColumn(SplitRow[1]);
					Else
						Values = New Array;
						Values.Add(SourceObject_[SplitRow[0]]);
					EndIf;
					
				Else // Regular or additional Attributes.
					
					Values = New Array;
					
					If AttributeNameObjectIS = "Presentation" Then
						
						Values.Add(String(SourceObject_));
						
					ElsIf Find(AttributeNameObjectIS, ".") > 0
							And Not PropsRule.IsAdditionalAttributeIS Then
						
						AttributeValue = Common.ObjectAttributeValue(Source, AttributeNameObjectIS);
						Values.Add(AttributeValue);
						
					ElsIf PropsRule.IsAdditionalAttributeIS Then
						
						QueryText =
							"SELECT ALLOWED TOP 1
							|	AdditionalAttributes.Value AS AttributeValue
							|FROM
							|	&AdditionalAttributes AS AdditionalAttributes
							|WHERE
							|	AdditionalAttributes.Ref = &Source
							|	AND AdditionalAttributes.Property = &Property";
						QueryText = StrReplace(
							QueryText,
							"&AdditionalAttributes",
							SourceMetadata.FullName() +"." + "AdditionalAttributes");
						
						Query = New Query(QueryText);
						Query.SetParameter("Source", Source);
						Query.SetParameter("Property", PropsRule.AdditionalAttributeIS);
						Values = Query.Execute().Unload().UnloadColumn("AttributeValue");
						
					Else // The usual Attribute of the object.
						
						Try
							
							Values.Add(SourceObject_[AttributeNameObjectIS]);
							
						Except // If there is no Attribute, we will issue a clear error message.
							
							Info = ErrorInfo();
							If SourceMetadata.Attributes.Find(AttributeNameObjectIS) = Undefined
								And AttributeNameObjectIS <> "Presentation" Then
								Found = False;
								For Each StandardAttribute In SourceMetadata.StandardAttributes Do
									If StandardAttribute.Name = AttributeNameObjectIS Then
										Found = True;
										Break;
									EndIf;
								EndDo;
								If Not Found Then
									MessageText = StrTemplate(
										NStr("vi = 'Không tìm thấy mục tin %1 đã chỉ ra trong quy tắc tích hợp với 1C:Document Management.
											|Hãy kiểm tra quy tắc tích hợp hoặc liên hệ với người quản trị.';
											|ru = 'Не найден реквизит %1, указанный в правиле интеграции с 1С:Документооборотом.
											|Проверьте правило интеграции или обратитесь к администратору.';
											|en = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
											|Check the integration rule or contact the administrator.'; fa = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
											|Check the integration rule or contact the administrator.';
											|it = 'Non è stato trovato l''attributo %1 indicato nella regola di integrazione con 1C:Document Management.
											|Verificare la regola di integrazione oppure rivolgersi all''amministratore.';
											|pl = 'Nie znaleziono atrybutu %1, określonego w regule integracji z 1С:Document Management.
											|Sprawdź regułę integracji lub zwróć się do administratora.';
											|tr = '1C:Document Management ile entegrasyon kuralında belirtilen %1 özniteliği bulunamadı.
											|Entegrasyon kuralını kontrol et veya yönetici ile iletişime geç.'",
											Common.DefaultLanguageCode()),
										PropsRule.AttributeNameObjectIS);
									WriteLogEvent(
										IntegrationWith1CDocumentManagementCore.EventLogEventName(),
										EventLogLevel.Error,,
										TheseRules.Ref,
										MessageText);
									Raise MessageText;
								EndIf;
							EndIf;
							
							// Another mistake.
							Raise ErrorProcessing.DetailErrorDescription(Info);
							
						EndTry;
						
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(TableName) Then
					Table = AttributesStructure1[TableName];
				Else
					Table = New Array;
					Table.Add(AttributesStructure1);
				EndIf;
				
				For ValueNumber = 0 To Values.Count() - 1 Do
					
					Value = Values[ValueNumber];
					
					StandardProcessing = True;
					IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInXDTOObjectPropertyByValue(
						Value,
						Table[ValueNumber],
						TheseRules.ObjectTypeDM,
						AttributeName,
						AttributeTypeBefore,
						StandardProcessing);
					
					If Not StandardProcessing Then
						Continue;
					EndIf;
					
					For ItemNumber = 0 To Table.Count() - 1 Do
						
						If Values.Count() > 1 And ValueNumber <> ItemNumber Then
							Continue;
						EndIf;
						
						Item = Table[ItemNumber];
						
						If IsPrimitiveType(AttributeTypeBefore) Then
							Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, Value);
						ElsIf ValueIsFilled(Value) Then // The reference type on the BEFORE side.
							Item[AttributeName] = String(Value);
							If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Value) Then
								Item[AttributeName + "ID"] = String(Value.UUID());
								Item[AttributeName + "Type"] = Value.Metadata().FullName();
							ElsIf IsEnum(Value) Then
								If Common.RefExists(Value) Then
									Item[AttributeName + "ID"] = Common.EnumerationValueName(Value);
								EndIf;
								Item[AttributeName + "Type"] = Value.Metadata().FullName();
							Else // The primitive type is on the IC side.
								Item[AttributeName + "ID"] = String(Value);
								Item[AttributeName + "Type"] = "String";
							EndIf;
						EndIf;
						
					EndDo;
					
				EndDo;
				
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				If ValueIsFilled(TableName) Then
					Table = AttributesStructure1[TableName];
				Else
					Table = New Array;
					Table.Add(AttributesStructure1);
				EndIf;
				
				For Each Item In Table Do
					
					If IsPrimitiveType(AttributeTypeBefore) Then
						Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, PropsRule.AttributeValueDM);
					Else // The reference type on the BEFORE side.
						Item[AttributeName] = PropsRule.AttributeValueDM;
						Item[AttributeName + "ID"] = PropsRule.AttributeValueDMID;
						Item[AttributeName + "Type"] = PropsRule.AttributeValueDMType;
					EndIf;
					
				EndDo;
				
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", SourceObject_);
				Parameters.Insert("Result", Undefined);
				Parameters.Insert("ResultID", Undefined);
				Parameters.Insert("ResultType", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				StandardProcessing = True;
				IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInXDTOObjectPropertyByValue(
					Parameters.Result,
					AttributesStructure1,
					TheseRules.ObjectTypeDM,
					AttributeName,
					AttributeTypeBefore,
					StandardProcessing);
				
				If StandardProcessing Then
					
					If ValueIsFilled(TableName) Then
						Table = AttributesStructure1[TableName];
					Else
						Table = New Array;
						Table.Add(AttributesStructure1);
					EndIf;
					
					For Each Item In Table Do
						
						If IsPrimitiveType(AttributeTypeBefore) Then
							Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, Parameters.Result);
						ElsIf ValueIsFilled(Parameters.Result) Then // The reference type on the BEFORE side.
							Item[AttributeName] = String(Parameters.Result);
							If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Parameters.Result) Then
								Item[AttributeName + "ID"] = String(Parameters.Result.UUID());
								Item[AttributeName + "Type"] = Parameters.Result.Metadata().FullName();
							ElsIf IsEnum(Parameters.Result) Then
								If Common.RefExists(Parameters.Result) Then
									Item[AttributeName + "ID"] = Common.EnumerationValueName(Parameters.Result);
								EndIf;
								Item[AttributeName + "Type"] = Parameters.Result.Metadata().FullName();
							ElsIf ValueIsFilled(Parameters.ResultID) And ValueIsFilled(Parameters.ResultType) Then
								Item[AttributeName + "ID"] = Parameters.ResultID;
								Item[AttributeName + "Type"] = Parameters.ResultType;
							Else // The primitive type is on the IC side.
								Item[AttributeName + "Type"] = "String";
							EndIf;
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
		Else // Additional Attributes on the DO side.
			
			AttributeTypeBefore = ObjectAttributeBefore.Type[0].Value;
			
			Table = AttributesStructure1.Properties;
			Item = Table.Add();
			Item.PropertyType = ObjectAttributeBefore.AdditionalAttribute5Type;
			Item.PropertyID = ObjectAttributeBefore.AdditionalAttribute5ID;
			Item.Property = "";
			
			For Each Type In ObjectAttributeBefore.Type Do
				DataAboutType = New Structure("xdtoClassName, presentation");
				DataAboutType.xdtoClassName = Type.Value;
				DataAboutType.presentation = Type.Presentation;
				Item.AvailableTypeList.Add(DataAboutType);
			EndDo;
			
			If PropsRule.Variant = OptionProps() Then
				
				AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
				Value = Undefined;
				
				// We get the value of the props of the IP object.
				If AttributeNameObjectIS = "Presentation" Then
					
					Value = String(SourceObject_);
					
				ElsIf Find(AttributeNameObjectIS, ".") > 0 And Not PropsRule.IsAdditionalAttributeIS Then
					
					Value = Common.ObjectAttributeValue(Source, AttributeNameObjectIS);
					
				ElsIf PropsRule.IsAdditionalAttributeIS Then
					
					QueryText =
						"SELECT ALLOWED TOP 1
						|	AdditionalAttributes.Value AS Value
						|FROM
						|	&AdditionalAttributes AS AdditionalAttributes
						|WHERE
						|	AdditionalAttributes.Ref = &Source
						|	AND AdditionalAttributes.Property = &Property";
					QueryText = StrReplace(
						QueryText,
						"&AdditionalAttributes",
						SourceMetadata.FullName() +"." + "AdditionalAttributes");
					
					Query = New Query(QueryText);
					Query.SetParameter("Source", Source);
					Query.SetParameter("Property", PropsRule.AdditionalAttributeIS);
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						Value = Selection.Value;
					EndIf;
					
				Else // The usual Attribute of the object.
					
					Try
						
						Value = SourceObject_[AttributeNameObjectIS];
						
					Except // If there is no Attribute, we will issue a clear error message.
						
						Info = ErrorInfo();
						If SourceMetadata.Attributes.Find(AttributeNameObjectIS) = Undefined
							And AttributeNameObjectIS <> "Presentation" Then
							Found = False;
							For Each StandardAttribute In SourceMetadata.StandardAttributes Do
								If StandardAttribute.Name = AttributeNameObjectIS Then
									Found = True;
									Break;
								EndIf;
							EndDo;
							If Not Found Then
								MessageText = StrTemplate(
									NStr("vi = 'Không tìm thấy mục tin %1 đã chỉ ra trong quy tắc tích hợp với 1C:Document Management.
										|Hãy kiểm tra quy tắc tích hợp hoặc liên hệ với người quản trị.';
										|ru = 'Не найден реквизит %1, указанный в правиле интеграции с 1С:Документооборотом.
										|Проверьте правило интеграции или обратитесь к администратору.';
										|en = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
										|Check the integration rule or contact the administrator.'; fa = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
										|Check the integration rule or contact the administrator.';
										|it = 'Non è stato trovato l''attributo %1 indicato nella regola di integrazione con 1C:Document Management.
										|Verificare la regola di integrazione oppure rivolgersi all''amministratore.';
										|pl = 'Nie znaleziono atrybutu %1, określonego w regule integracji z 1С:Document Management.
										|Sprawdź regułę integracji lub zwróć się do administratora.';
										|tr = '1C:Document Management ile entegrasyon kuralında belirtilen %1 özniteliği bulunamadı.
										|Entegrasyon kuralını kontrol et veya yönetici ile iletişime geç.'",
										Common.DefaultLanguageCode()),
									AttributeNameObjectIS);
								WriteLogEvent(
									IntegrationWith1CDocumentManagementCore.EventLogEventName(),
									EventLogLevel.Error,,
									TheseRules.Ref,
									MessageText);
								Raise MessageText;
							EndIf;
						EndIf;
						
						// Another mistake.
						Raise ErrorProcessing.DetailErrorDescription(Info);
						
					EndTry;
					
				EndIf;
				
				If IsPrimitiveType(AttributeTypeBefore) Then
					Item["Value"] = ConvertValueToPrimitiveType(AttributeTypeBefore, Value);
				ElsIf ValueIsFilled(Value) Then // The reference type on the BEFORE side.
					Item["Value"] = String(Value);
					If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Value) Then
						Item["ValueID"] = String(Value.UUID());
						Item["ValueType"] = Value.Metadata().FullName();
					ElsIf IsEnum(Value) Then
						If Common.RefExists(Value) Then
							Item["ValueID"] = Common.EnumerationValueName(Value);
						EndIf;
						Item["ValueType"] = Value.Metadata().FullName();
					Else // The primitive type is on the IC side.
						Item["ValueID"] = String(Value);
						Item["ValueType"] = AttributeTypeBefore;
					EndIf;
				EndIf;
				
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				Item["Value"] = PropsRule.AttributeValueDM;
				Item["ValueID"] = PropsRule.AttributeValueDMID;
				Item["ValueType"] = PropsRule.AttributeValueDMType;
				
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", SourceObject_);
				Parameters.Insert("Result", Undefined);
				Parameters.Insert("ResultID", Undefined);
				Parameters.Insert("ResultType", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				StandardProcessing = True;
				IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInXDTOObjectPropertyByValue(
					Parameters.Result,
					AttributesStructure1,
					TheseRules.ObjectTypeDM,
					AttributeName,
					AttributeTypeBefore,
					StandardProcessing);
				
				If StandardProcessing Then
				
					If IsPrimitiveType(AttributeTypeBefore) Then
						Item["Value"] = ConvertValueToPrimitiveType(AttributeTypeBefore, Parameters.Result);
					ElsIf ValueIsFilled(Parameters.Result) Then // The reference type on the BEFORE side.
						Item["Value"] = String(Parameters.Result);
						If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Parameters.Result) Then
							Item["ValueID"] = String(Parameters.Result.UUID());
							Item["ValueType"] = Parameters.Result.Metadata().FullName();
						ElsIf IsEnum(Parameters.Result) Then
							If Common.RefExists(Parameters.Result) Then
								Item["ValueID"] = Common.EnumerationValueName(Parameters.Result);
							EndIf;
							Item["ValueType"] = Parameters.Result.Metadata().FullName();
						ElsIf ValueIsFilled(Parameters.ResultID) And ValueIsFilled(Parameters.ResultType) Then
							Item["ValueID"] = Parameters.ResultID;
							Item["ValueType"] = Parameters.ResultType;
						Else // The primitive type is on the IC side.
							Item["ValueType"] = "String";
						EndIf;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If AttributesStructure1.Property("DeletionMark") Then
		AttributesStructure1.DeletionMark = SourceObject_.DeletionMark;
	EndIf;
	
	If TheseRules.ObjectTypeDM <> "DMCorrespondent" Then
		AttributesStructure1.Files = IntegrationWith1CDocumentManagementCore.PrintedFormsToCreate(
			Source,
			IntegrationWith1CDocumentManagement.AttachedPrintedForms(TheseRules.AttachedPrintedForms),
			TheseRules.TypeOfSavedPrintedFormFile,
			ControlOverSendingFiles,
			UpdateOnly);
	EndIf;
	
	// Requests for payment.
	If IsRequestForPayment Then
		FillInPaymentRequestDetails(AttributesStructure1);
	EndIf;
	
EndProcedure

// Fills in the details of the form from the data of the consumer object.
//
// Parameters:
//   Source - AnyRef - reference to the IP object.
//   Form - ClientApplicationForm - the form of the 1C object:Document management.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement, Structure - the applicable rule.
//
Procedure FillInMapItemFormUpToRule(Source, Form, Rule) Export
	
	// A rule passed as a link needs to be fetched by a query.
	If TypeOf(Rule) = Type("CatalogRef.RulesForIntegrationWith1CDocumentManagement") Then
		TheseRules = TheseRulesForUploading(Rule);
	Else // The data structure is transmitted immediately.
		TheseRules = Rule;
	EndIf;
	
	FillParameters = New Structure("documentType", DocumentViewFromRule(TheseRules));
	
	MatchingXDTPropertiesAndProps = MatchingXDTPropertiesAndObjectFormDetailsTo(Form.Type);
	SourceObject_ = Source.GetObject();
	SourceMetadata = Source.Metadata();
	Settings_View = Undefined;
	
	ObjectAttributesBefore = ObjectAttributesBefore(TheseRules.ObjectTypeDM, FillParameters, Settings_View);
	
	IsRequestForPayment = False;
	If Settings_View <> Undefined
			And IntegrationWith1CDocumentManagementCore.PropertyExists(Settings_View, "isAPaymentRequest")
			And Settings_View.isAPaymentRequest = True Then
		IsRequestForPayment = True;
	EndIf;
	If IsRequestForPayment Then
		MatchingXDTPropertiesAndProps.Insert("recipient", "Recipient");
	EndIf;
	
	For Each ObjectAttributeBefore In ObjectAttributesBefore Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("IsAdditionalAttributeDM", ObjectAttributeBefore.AdditionalAttribute5);
		If ObjectAttributeBefore.AdditionalAttribute5 Then
			FilterParameters.Insert("AdditionalAttributeDMID", ObjectAttributeBefore.AdditionalAttribute5ID);
			FilterParameters.Insert("AdditionalAttributeDMType", ObjectAttributeBefore.AdditionalAttribute5Type);
			FilterParameters.Insert("ThisIsTable", False);
			FilterParameters.Insert("Table", "");
		Else
			FilterParameters.Insert("AttributeNameObjectDM", ObjectAttributeBefore.Name);
			FilterParameters.Insert("ThisIsTable", ObjectAttributeBefore.ThisIsTable);
			FilterParameters.Insert("Table", ObjectAttributeBefore.Table);
		EndIf;
		
		FoundRulesForBankingDetails = TheseRules.AttributeFillingRulesDM.FindRows(FilterParameters);
		If FoundRulesForBankingDetails.Count() = 0 Then
			Continue;
		EndIf;
		PropsRule = FoundRulesForBankingDetails[0]; // CatalogTabularSectionRow.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM
		
		If Not ObjectAttributeBefore.AdditionalAttribute5 Then
			
			If ValueIsFilled(ObjectAttributeBefore.Table) Then
				
				SplitRow = StrSplit(ObjectAttributeBefore.Table, ".", False);
				OwnerProperty = MatchingXDTPropertiesAndProps[SplitRow[0]];
				TableDetails = OwnerProperty[SplitRow[1]];
				TableName = TableDetails[0];
				AttributeName = TableDetails[1][ObjectAttributeBefore.Name];
				
			ElsIf ObjectAttributeBefore.ThisIsTable Then
				
				SplitRow = StrSplit(ObjectAttributeBefore.Name, ".", False);
				OwnerProperty = MatchingXDTPropertiesAndProps[SplitRow[0]];
				TableDetails = OwnerProperty[SplitRow[1]];
				TableName = TableDetails[0];
				AttributeName = "";
				
			Else
				
				TableName = "";
				AttributeName = MatchingXDTPropertiesAndProps[ObjectAttributeBefore.Name];
				
			EndIf;
			
			If ObjectAttributeBefore.ThisIsTable Then
				
				Form[TableName].Clear();
				
				If PropsRule.Variant = OptionProps() Then // Fill it with empty lines.
					
					TabularSection = SourceObject_[PropsRule.AttributeNameObjectIS];
					For Counter = 1 To TabularSection.Count() Do
						Form[TableName].Add();
					EndDo;
					
				ElsIf PropsRule.Variant = TablePropsOption() Then // Add a single line.
					
					Form[TableName].Add();
					
				ElsIf PropsRule.Variant = VariantExpression() Then // We'll load it from the result table.
					
					Parameters = New Structure;
					Parameters.Insert("Source", SourceObject_);
					Parameters.Insert("Result", Undefined);
					
					IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
						PropsRule.ComputedExpression,
						Parameters);
					
					StandardProcessing = True;
					IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInXDTOObjectPropertyByValue(
						Parameters.Result,
						Form,
						TheseRules.ObjectTypeDM,
						TableName,
						Undefined,
						StandardProcessing);
					
					If Not StandardProcessing Then
						Continue;
					EndIf;
					
					If TypeOf(Parameters.Result) = Type("ValueTable") Then
						TableColumns1 = Parameters.Result.Columns; // ValueTableColumnCollection
						
						For Each ResultString1 In Parameters.Result Do
							FormString = Form[TableName].Add();
							For Each Column In TableColumns1 Do
								If Not FormString.Property(Column.Name) Then
									Continue;
								EndIf;
								Value = ResultString1[Column.Name];
								FormString[Column.Name] = Value;
								If Not FormString.Property(Column.Name + "ID") Then
									Continue;
								EndIf;
								If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Value) Then
									FormString[Column.Name + "ID"] = String(Value.UUID());
									FormString[Column.Name + "Type"] = Value.Metadata().FullName();
								ElsIf IsEnum(Value) Then
									If Common.RefExists(Value) Then
										FormString[Column.Name + "ID"] = Common.EnumerationValueName(Value);
									EndIf;
									FormString[Column.Name + "Type"] = Value.Metadata().FullName();
								Else
									FormString[Column.Name + "ID"] = String(Value);
									FormString[Column.Name + "Type"] = "String";
								EndIf;
							EndDo;
						EndDo;
					EndIf;
					
				Else // The values specified for the Attributes: add a single line.
					
					Form[TableName].Add();
					
				EndIf;
				
				Continue;
				
			EndIf; // This is a table.
			
			AttributeTypeBefore = ObjectAttributeBefore.Type[0].Value;
			
			If PropsRule.Variant = OptionProps() Then
				
				AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
				
				If ValueIsFilled(PropsRule.Table) Then // Attributes of the table part.
					
					SplitRow = StrSplit(AttributeNameObjectIS, ".");
					If SplitRow.Count() = 2 Then
						TabularSection = SourceObject_[SplitRow[0]];
						Values = TabularSection.UnloadColumn(SplitRow[1]);
					Else
						Values = New Array;
						Values.Add(SourceObject_[SplitRow[0]]);
					EndIf;
					
				Else // Regular or additional Attributes.
					
					Values = New Array;
					
					If AttributeNameObjectIS = "Presentation" Then
						
						Values.Add(String(SourceObject_));
						
					ElsIf Find(AttributeNameObjectIS, ".") > 0
							And Not PropsRule.IsAdditionalAttributeIS Then
						
						AttributeValue = Common.ObjectAttributeValue(Source, AttributeNameObjectIS);
						Values.Add(AttributeValue);
						
					Else
						
						If PropsRule.IsAdditionalAttributeIS Then
							
							QueryText =
								"SELECT ALLOWED TOP 1
								|	AdditionalAttributes.Value AS AttributeValue
								|FROM
								|	&AdditionalAttributes AS AdditionalAttributes
								|WHERE
								|	AdditionalAttributes.Ref = &Source
								|	AND AdditionalAttributes.Property = &Property";
							QueryText = StrReplace(
								QueryText,
								"&AdditionalAttributes",
								SourceMetadata.FullName() +"." + "AdditionalAttributes");
							
							Query = New Query(QueryText);
							Query.SetParameter("Source", Source);
							Query.SetParameter("Property", PropsRule.AdditionalAttributeIS);
							Values = Query.Execute().Unload().UnloadColumn("AttributeValue");
							
						Else // The usual Attributes.
							
							Try
								
								Values.Add(SourceObject_[AttributeNameObjectIS]);
								
							Except // If there is no Attribute, we will issue a clear error message.
								
								Info = ErrorInfo();
								If SourceMetadata.Attributes.Find(AttributeNameObjectIS) = Undefined
									And PropsRule.AttributeNameObjectIS <> "Presentation" Then
									Found = False;
									For Each StandardAttribute In SourceMetadata.StandardAttributes Do
										If StandardAttribute.Name = PropsRule.AttributeNameObjectIS Then
											Found = True;
											Break;
										EndIf;
									EndDo;
									If Not Found Then
										MessageText = StrTemplate(
											NStr("vi = 'Không tìm thấy mục tin %1 đã chỉ ra trong quy tắc tích hợp với 1C:Document Management.
												|Hãy kiểm tra quy tắc tích hợp hoặc liên hệ với người quản trị.';
												|ru = 'Не найден реквизит %1, указанный в правиле интеграции с 1С:Документооборотом.
												|Проверьте правило интеграции или обратитесь к администратору.';
												|en = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
												|Check the integration rule or contact the administrator.'; fa = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
												|Check the integration rule or contact the administrator.';
												|it = 'Non è stato trovato l''attributo %1 indicato nella regola di integrazione con 1C:Document Management.
												|Verificare la regola di integrazione oppure rivolgersi all''amministratore.';
												|pl = 'Nie znaleziono atrybutu %1, określonego w regule integracji z 1С:Document Management.
												|Sprawdź regułę integracji lub zwróć się do administratora.';
												|tr = '1C:Document Management ile entegrasyon kuralında belirtilen %1 özniteliği bulunamadı.
												|Entegrasyon kuralını kontrol et veya yönetici ile iletişime geç.'",
												Common.DefaultLanguageCode()),
											PropsRule.AttributeNameObjectIS);
										WriteLogEvent(
											IntegrationWith1CDocumentManagementCore.EventLogEventName(),
											EventLogLevel.Error,,
											TheseRules.Ref,
											MessageText);
										Raise MessageText;
									EndIf;
								EndIf;
								
								// Another mistake.
								Raise ErrorProcessing.DetailErrorDescription(Info);
								
							EndTry;
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(TableName) Then
					Table = Form[TableName];
				Else
					Table = New Array;
					Table.Add(Form);
				EndIf;
				
				For ValueNumber = 0 To Values.Count() - 1 Do
					
					Value = Values[ValueNumber];
					
					StandardProcessing = True;
					IntegrationWith1CDocumentManagementCoreOverridable.WhenFillingInXDTOObjectPropertyByValue(
						Value,
						Table[ValueNumber],
						TheseRules.ObjectTypeDM,
						AttributeName,
						AttributeTypeBefore,
						StandardProcessing);
					
					If Not StandardProcessing Then
						Continue;
					EndIf;
					
					For ItemNumber = 0 To Table.Count() - 1 Do
						
						If Values.Count() > 1 And ValueNumber <> ItemNumber Then
							Continue;
						EndIf;
						
						Item = Table[ItemNumber];
						
						If IsPrimitiveType(AttributeTypeBefore) Then
							Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, Value);
						ElsIf ValueIsFilled(Value) Then
							Item[AttributeName] = String(Value);
							If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Value) Then
								Item[AttributeName + "ID"] = String(Value.UUID());
								Item[AttributeName + "Type"] = Value.Metadata().FullName();
							ElsIf IsEnum(Value) Then
								If Common.RefExists(Value) Then
									Item[AttributeName + "ID"] = Common.EnumerationValueName(Value);
								EndIf;
								Item[AttributeName + "Type"] = Value.Metadata().FullName();
							Else // The primitive type is on the IC side.
								Item[AttributeName + "ID"] = String(Value);
								Item[AttributeName + "Type"] = "String";
							EndIf;
						EndIf;
						
					EndDo;
					
				EndDo;
				
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				If ValueIsFilled(TableName) Then
					Table = Form[TableName];
				Else
					Table = New Array;
					Table.Add(Form);
				EndIf;
				
				For Each Item In Table Do
					
					If IsPrimitiveType(AttributeTypeBefore) Then
						Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, PropsRule.AttributeValueDM);
					Else
						Item[AttributeName] = PropsRule.AttributeValueDM;
						Item[AttributeName + "ID"] = PropsRule.AttributeValueDMID;
						Item[AttributeName + "Type"] = PropsRule.AttributeValueDMType;
					EndIf;
					
				EndDo;
				
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", SourceObject_);
				Parameters.Insert("Result", Undefined);
				Parameters.Insert("ResultID", Undefined);
				Parameters.Insert("ResultType", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				If ValueIsFilled(TableName) Then
					Table = Form[TableName];
				Else
					Table = New Array;
					Table.Add(Form);
				EndIf;
				
				For Each Item In Table Do
					If IsPrimitiveType(AttributeTypeBefore) Then
						Item[AttributeName] = ConvertValueToPrimitiveType(AttributeTypeBefore, Parameters.Result);
					ElsIf ValueIsFilled(Parameters.Result) Then // The reference type on the BEFORE side.
						Item[AttributeName] = String(Parameters.Result);
						If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Parameters.Result) Then
							Item[AttributeName + "ID"] = String(Parameters.Result.UUID());
							Item[AttributeName + "Type"] = Parameters.Result.Metadata().FullName();
						ElsIf IsEnum(Parameters.Result) Then
							If Common.RefExists(Parameters.Result) Then
								Item[AttributeName + "ID"] = Common.EnumerationValueName(Parameters.Result);
							EndIf;
							Item[AttributeName + "Type"] = Parameters.Result.Metadata().FullName();
						ElsIf ValueIsFilled(Parameters.ResultID)
								And ValueIsFilled(Parameters.ResultType) Then
							Item[AttributeName + "ID"] = Parameters.ResultID;
							Item[AttributeName + "Type"] = Parameters.ResultType;
						Else // The primitive type is on the IC side.
							Item[AttributeName + "Type"] = "String";
						EndIf;
					EndIf;
				EndDo;
				
			EndIf;
			
		Else // Additional Attributes on the DO side.
			
			AttributeTypeBefore = ObjectAttributeBefore.Type[0].Value;
			
			FilterParameters = New Structure("PropertyType, PropertyID",
				ObjectAttributeBefore.AdditionalAttribute5Type,
				ObjectAttributeBefore.AdditionalAttribute5ID);
			ArrayOfStringsAndBankingDetails = Form.Properties.FindRows(FilterParameters);
			If ArrayOfStringsAndBankingDetails.Count() > 0 Then
				Item = ArrayOfStringsAndBankingDetails[0];
			Else
				// Additional Attributes belong to a specific type of document.
				Item = Form.Properties.Add();
				Item.Property = ObjectAttributeBefore.Presentation;
				Item.PropertyType = ObjectAttributeBefore.AdditionalAttribute5Type;
				Item.PropertyID = ObjectAttributeBefore.AdditionalAttribute5ID;
				Item.RequiredToFill = ObjectAttributeBefore.Mandatory;
				Item.AvailableTypeList = ObjectAttributeBefore.Type;
			EndIf;
			
			If PropsRule.Variant = OptionProps() Then
				
				AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
				Value = Undefined;
				
				If AttributeNameObjectIS = "Presentation" Then
					
					Value = String(SourceObject_);
					
				ElsIf Find(AttributeNameObjectIS, ".") > 0 And Not PropsRule.IsAdditionalAttributeIS Then
					
					Value = Common.ObjectAttributeValue(Source, AttributeNameObjectIS);
					
				ElsIf PropsRule.IsAdditionalAttributeIS Then
					
					QueryText =
						"SELECT ALLOWED TOP 1
						|	AdditionalAttributes.Value AS Value
						|FROM
						|	&AdditionalAttributes AS AdditionalAttributes
						|WHERE
						|	AdditionalAttributes.Ref = &Source
						|	AND AdditionalAttributes.Property = &Property";
					QueryText = StrReplace(
						QueryText,
						"&AdditionalAttributes",
						SourceMetadata.FullName() +"." + "AdditionalAttributes");
					
					Query = New Query(QueryText);
					Query.SetParameter("Source", Source);
					Query.SetParameter("Property", PropsRule.AdditionalAttributeIS);
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						Value = Selection.Value;
					EndIf;
					
				Else // The usual Attribute of the object.
					
					Try
						
						Value = SourceObject_[AttributeNameObjectIS];
						
					Except // If there is no Attribute, we will issue a clear error message.
						
						Info = ErrorInfo();
						If SourceMetadata.Attributes.Find(AttributeNameObjectIS) = Undefined
							And AttributeNameObjectIS <> "Presentation" Then
							Found = False;
							For Each StandardAttribute In SourceMetadata.StandardAttributes Do
								If StandardAttribute.Name = AttributeNameObjectIS Then
									Found = True;
									Break;
								EndIf;
							EndDo;
							If Not Found Then
								MessageText = StrTemplate(
									NStr("vi = 'Không tìm thấy mục tin %1 đã chỉ ra trong quy tắc tích hợp với 1C:Document Management.
										|Hãy kiểm tra quy tắc tích hợp hoặc liên hệ với người quản trị.';
										|ru = 'Не найден реквизит %1, указанный в правиле интеграции с 1С:Документооборотом.
										|Проверьте правило интеграции или обратитесь к администратору.';
										|en = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
										|Check the integration rule or contact the administrator.'; fa = 'The %1 attribute specified in the rule of integration with 1C:Document Management is not found.
										|Check the integration rule or contact the administrator.';
										|it = 'Non è stato trovato l''attributo %1 indicato nella regola di integrazione con 1C:Document Management.
										|Verificare la regola di integrazione oppure rivolgersi all''amministratore.';
										|pl = 'Nie znaleziono atrybutu %1, określonego w regule integracji z 1С:Document Management.
										|Sprawdź regułę integracji lub zwróć się do administratora.';
										|tr = '1C:Document Management ile entegrasyon kuralında belirtilen %1 özniteliği bulunamadı.
										|Entegrasyon kuralını kontrol et veya yönetici ile iletişime geç.'",
										Common.DefaultLanguageCode()),
									AttributeNameObjectIS);
								WriteLogEvent(
									IntegrationWith1CDocumentManagementCore.EventLogEventName(),
									EventLogLevel.Error,,
									TheseRules.Ref,
									MessageText);
								Raise MessageText;
							EndIf;
						EndIf;
						
						// Another mistake.
						Raise ErrorProcessing.DetailErrorDescription(Info);
						
					EndTry;
					
				EndIf;
				
				If IsPrimitiveType(AttributeTypeBefore) Then
					Item["Value"] = ConvertValueToPrimitiveType(AttributeTypeBefore, Value);
				ElsIf ValueIsFilled(Value) Then
					Item["Value"] = String(Value);
					If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Value) Then
						Item["ValueID"] = String(Value.UUID());
						Item["ValueType"] = Value.Metadata().FullName();
					ElsIf IsEnum(Value) Then
						If Common.RefExists(Value) Then
							Item["ValueID"] = Common.EnumerationValueName(Value);
						EndIf;
						Item["ValueType"] = Value.Metadata().FullName();
					Else
						Item["ValueID"] = String(Value);
						Item["ValueType"] = AttributeTypeBefore;
					EndIf;
					
				EndIf;
				
			ElsIf PropsRule.Variant = OptionValue_() Then
				
				Item["Value"] = PropsRule.AttributeValueDM;
				Item["ValueID"]  = PropsRule.AttributeValueDMID;
				Item["ValueType"] = PropsRule.AttributeValueDMType;
				
			ElsIf PropsRule.Variant = VariantExpression() Then
				
				Parameters = New Structure;
				Parameters.Insert("Source", SourceObject_);
				Parameters.Insert("Result", Undefined);
				Parameters.Insert("ResultID", Undefined);
				Parameters.Insert("ResultType", Undefined);
				
				IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
					PropsRule.ComputedExpression,
					Parameters);
				
				If IsPrimitiveType(AttributeTypeBefore) Then
					Item["Value"] = ConvertValueToPrimitiveType(AttributeTypeBefore, Parameters.Result);
				ElsIf ValueIsFilled(Parameters.Result) Then
					Item["Value"] = String(Parameters.Result);
					If IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(Parameters.Result) Then
						Item["ValueID"] = String(Parameters.Result.UUID());
						Item["ValueType"] = Parameters.Result.Metadata().FullName();
					ElsIf IsEnum(Parameters.Result) Then
						If Common.RefExists(Parameters.Result) Then
							Item["ValueID"] = Common.EnumerationValueName(Parameters.Result);
						EndIf;
						Item["ValueType"] = Parameters.Result.Metadata().FullName();
					ElsIf ValueIsFilled(Parameters.ResultID) And ValueIsFilled(Parameters.ResultType) Then
						Item["ValueID"] = Parameters.ResultID;
						Item["ValueType"] = Parameters.ResultType;
					Else // The primitive type is on the IC side.
						Item["ValueType"] = "String";
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Form.DeletionMark = SourceObject_.DeletionMark;
	
	ControlOverSendingFiles = IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles();
	
	If TheseRules.ObjectTypeDM <> "DMCorrespondent" Then
		PrintedFormsToCreate = IntegrationWith1CDocumentManagementCore.PrintedFormsToCreate(
			Source,
			IntegrationWith1CDocumentManagement.AttachedPrintedForms(TheseRules.AttachedPrintedForms),
			TheseRules.TypeOfSavedPrintedFormFile,
			ControlOverSendingFiles,
			False,
			Form.UUID);
		For Each CreationParameters In PrintedFormsToCreate Do
			Files = Form.Files; // FormDataCollection
			FilesRow = Files.Add();
			FilesRow.TempFileStorageAddress = CreationParameters.TempFileStorageAddress;
			FilesRow.Description = CreationParameters.CurrentFile.Description;
			FilesRow.Extension = CreationParameters.CurrentFile.Extension;
			FilesRow.PictureIndex =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
					FilesRow.Extension);
			FilesRow.CreationDate = CreationParameters.CurrentFile.ModificationDate;
			FilesRow.UniversalModificationDate = CreationParameters.CurrentFile.UniversalModificationDate;
			FilesRow.Size = CreationParameters.CurrentFile.Size;
			FilesRow.SignedEncryptedPictureNumber = -1;
		EndDo;
	EndIf;
	
	Form.ControlOverSendingFiles = New ValueStorage(ControlOverSendingFiles);
	
	// Requests for payment.
	If IsRequestForPayment Then
		FillInPaymentRequestDetails(Form);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.OnFillFormOfTheObjectDMByObjectIS(Source,
		Form,
		Rule.Ref);
	
EndProcedure

// Updates the integration rules that use the template when it is changed on the DO side.
//
// Parameters:
//   XDTOTemplate - XDTODataObject - modified template.
//
Procedure UpdateRulesByTemplate(XDTOTemplate) Export
	
	If XDTOTemplate.Properties().Get("blockDerivedDocuments") <> Undefined
			And XDTOTemplate.IsSet("blockDerivedDocuments") Then
		TemplateForbidModification = XDTOTemplate.blockDerivedDocuments;
	Else
		TemplateForbidModification = False;
	EndIf;
	
	RuleRequest = New Query(
		"SELECT
		|	Rules.Ref AS Rule,
		|	Rules.ObjectTypeDM AS ObjectTypeDM
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	Rules.TemplateType = &TemplateType
		|	AND Rules.TemplateID = &TemplateID
		|	AND NOT Rules.DeletionMark");
	RuleRequest.SetParameter("TemplateType", XDTOTemplate.objectID.type);
	RuleRequest.SetParameter("TemplateID", XDTOTemplate.objectID.ID);
	
	RuleSelection_ = RuleRequest.Execute().Select();
	While RuleSelection_.Next() Do
		
		If XDTOTemplate.Properties().Get("documentType") = Undefined
				Or Not XDTOTemplate.IsSet("documentType")
				Or Not ValueIsFilled(XDTOTemplate.documentType.objectID.ID)
				Or Not ValueIsFilled(XDTOTemplate.documentType.objectID.type) Then
			Continue;
		EndIf;
		
		FillParameters = New Structure;
		FillParameters.Insert("documentType",
			New Structure("ID, type, name",
				XDTOTemplate.documentType.objectID.ID,
				XDTOTemplate.documentType.objectID.type,
				XDTOTemplate.documentType.name));
		
		ObjectAttributesBefore = ObjectAttributesBefore(
			RuleSelection_.ObjectTypeDM,
			FillParameters);
		
		Rule = RuleSelection_.Rule.GetObject();
		Rule.Lock();
		NeedEntry = False;
		
		AttributeNumber = 0;
		While AttributeNumber <= Rule.AttributeFillingRulesDM.Count() - 1 Do
			
			PropsRule = Rule.AttributeFillingRulesDM[AttributeNumber]; // CatalogTabularSectionRow.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM
			AttributeName = PropsRule.AttributeNameObjectDM;
			If AttributeName = "performanceDate" Then
				NameOfTemplateProps = "performanceTerm";
			Else
				NameOfTemplateProps = AttributeName;
			EndIf;
			
			// Let's check if the props defined in the rule exist.
			FilterStructure1 = New Structure("AdditionalAttribute5",
				PropsRule.IsAdditionalAttributeDM);
			If PropsRule.IsAdditionalAttributeDM Then
				FilterStructure1.Insert("AdditionalAttribute5ID",
					PropsRule.AdditionalAttributeDMID);
				FilterStructure1.Insert("ThisIsTable", False);
				FilterStructure1.Insert("Table", "");
			Else
				FilterStructure1.Insert("Name", AttributeName);
				FilterStructure1.Insert("ThisIsTable", PropsRule.ThisIsTable);
				FilterStructure1.Insert("Table", PropsRule.Table);
			EndIf;
			
			FoundAttributes = ObjectAttributesBefore.FindRows(FilterStructure1);
			If FoundAttributes.Count() = 0 Then
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					MessageText = StrTemplate(
						NStr("vi = 'Đã xóa quy tắc điền mục tin %1 không có trong chứng từ';
							|ru = 'Очищено правило заполнения реквизита %1, отсутствующего в документе';
							|en = 'Filling rule of attribute %1 not present in the document is cleared'; fa = 'Filling rule of attribute %1 not present in the document is cleared';
							|it = 'Regola di compilazione cancellata dell''attributo %1 mancante nel documento';
							|pl = 'Wyczyszczono regułę wypełnienia atrybutu %1, którego nie ma w dokumencie';
							|tr = 'Belgede eksik olan %1 özniteliğini doldurma kuralı silindi'",
							Common.DefaultLanguageCode()),
						AttributeName);
				Else
					MessageText = NStr("vi = 'Đã xóa quy tắc điền mục tin bổ sung không có trong chứng từ';
										|ru = 'Очищено правило заполнения дополнительного реквизита, отсутствующего в документе';
										|en = 'Filling rule of the additional attribute missing in the document is cleared'; fa = 'Filling rule of the additional attribute missing in the document is cleared';
										|it = 'Regola di compilazione cancellata dell''attributo aggiuntivo mancante nel documento';
										|pl = 'Wyczyszczono regułę wypełnienia dodatkowego atrybutu, którego nie ma w dokumencie';
										|tr = 'Belgede eksik olan ek öznitelikleri doldurma kuralı silindi'",
						Common.DefaultLanguageCode());
				EndIf;
				WriteLogEvent(
					IntegrationWith1CDocumentManagementCore.EventLogEventName(),
					EventLogLevel.Warning,,
					Rule.Ref,
					MessageText);
					
				NeedEntry = True;
				Rule.AttributeFillingRulesDM.Delete(PropsRule);
				
				Continue;
				
			EndIf;
			
			If Not PropsRule.IsAdditionalAttributeDM Then
				If XDTOTemplate.Properties().Get(NameOfTemplateProps) <> Undefined Then
					TemplateAttribute = XDTOTemplate[NameOfTemplateProps];
				Else
					TemplateAttribute = Undefined;
				EndIf;
			Else
				If XDTOTemplate.IsSet("additionalProperties") Then
					TemplateAttribute = Undefined;
					For Each AdditionalAttribute5 In XDTOTemplate.additionalProperties Do
						If AdditionalAttribute5.objectID.ID = PropsRule.AdditionalAttributeDMID
							And AdditionalAttribute5.objectID.type = PropsRule.AdditionalAttributeDMType Then
								
							If AdditionalAttribute5.IsSet("propertySimpleValue") Then
								TemplateAttribute = AdditionalAttribute5.propertySimpleValue;
							ElsIf AdditionalAttribute5.IsSet("propertyObjectValue") Then
								TemplateAttribute = AdditionalAttribute5.propertyObjectValue;
							EndIf;
							Break;
							
						EndIf;
					EndDo;
				Else
					TemplateAttribute = Undefined;
				EndIf;
			EndIf;
			
			// Let's check if the value set by the template has not changed.
			If PropsRule.Variant = OptionTemplate()
				And TemplateAttribute = Undefined Then
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					MessageText = StrTemplate(
						NStr("vi = 'Đã xóa quy tắc điền mục tin %1 không có trong khuôn mẫu';
							|ru = 'Очищено правило заполнения реквизита %1, отсутствующего в шаблоне';
							|en = 'Filling rule of attribute %1 missing in the template is cleared'; fa = 'Filling rule of attribute %1 missing in the template is cleared';
							|it = 'Regola di compilazione cancellata dell''attributo %1 mancante nel modello';
							|pl = 'Wyczyszczono regułę wypełnienia atrybutu %1, którego nie ma w szablonie';
							|tr = 'Numunede eksik olan öznitelikleri %1 doldurma kuralı silindi'",
							Common.DefaultLanguageCode()),
						AttributeName);
				Else
					MessageText = NStr("vi = 'Đã xóa quy tắc điền mục tin bổ sung không có trong khuôn mẫu';
										|ru = 'Очищено правило заполнения дополнительного реквизита, отсутствующего в шаблоне';
										|en = 'Filling rule of the additional attribute missing in the template is cleared'; fa = 'Filling rule of the additional attribute missing in the template is cleared';
										|it = 'Regola di compilazione cancellata dell''attributo aggiuntivo mancante nel modello';
										|pl = 'Wyczyszczono regułę wypełnienia dodatkowego atrybutu, którego nie ma w szablonie';
										|tr = 'Numunede eksik olan ek öznitelikleri doldurma kuralı silindi'",
						Common.DefaultLanguageCode());
				EndIf;
				WriteLogEvent(
					IntegrationWith1CDocumentManagementCore.EventLogEventName(),
					EventLogLevel.Warning,,
					Rule.Ref,
					MessageText);
					
				NeedEntry = True;
				Rule.AttributeFillingRulesDM.Delete(PropsRule);
				Continue;
				
			EndIf;
			
			If TypeOf(TemplateAttribute) = Type("XDTODataObject") Then
				TemplateAttributeID = TemplateAttribute.objectID.ID;
				TemplateAttributeType = TemplateAttribute.objectID.type;
				TemplatePropsValue = TemplateAttribute.name;
				FilledInTemplate = ValueIsFilled(TemplateAttributeID);
			Else // Primitive type or Undefined.
				TemplateAttributeID = "";
				TemplateAttributeType = "";
				TemplatePropsValue = TemplateAttribute;
				FilledInTemplate = ValueIsFilled(TemplateAttribute);
			EndIf;
			
			// Has the value changed?
			If (ValueIsFilled(PropsRule.TemplateID)
					And PropsRule.TemplateID <> TemplateAttributeID)
				Or (Not ValueIsFilled(PropsRule.TemplateID)
					And PropsRule.TemplateMeaning <> TemplatePropsValue)
				Or (PropsRule.FilledInTemplate <> FilledInTemplate) Then
					
				NeedEntry = True;
					
				PropsRule.TemplateMeaning = TemplatePropsValue;
				PropsRule.TemplateID = TemplateAttributeID;
				PropsRule.TemplateType = TemplateAttributeType;
				PropsRule.FilledInTemplate = FilledInTemplate;
				
			EndIf;
			
			// The key details must be filled in.
			If PropsRule.Variant = OptionTemplate()
				And PropsRule.KeyAttribute_
				And Not FilledInTemplate Then
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					MessageText = StrTemplate(
						NStr("vi = 'Đã xóa dấu hiệu ""Chính"" trong mục tin %1 không có trong khuôn mẫu';
							|ru = 'Очищен признак ""Ключевой"" у реквизита %1, отсутствующего в шаблоне';
							|en = 'The ""Key"" check box of attribute %1 not present in the template is cleared'; fa = 'The ""Key"" check box of attribute %1 not present in the template is cleared';
							|it = 'Segno ""Chiave"" cancellato dell''attributo %1 mancante nel modello';
							|pl = 'Wyczyszczono oznakę ""Kluczowy"" dla atrybutu %1, którego nie ma w szablonie';
							|tr = 'Numunede eksik olan %1 özniteliğinin ""Anahtar"" bayrağı silindi'",
							Common.DefaultLanguageCode()),
						AttributeName);
				Else
					MessageText = NStr("vi = 'Đã xóa dấu hiệu ""Chính"" trong mục tin bổ sung không có trong khuôn mẫu';
										|ru = 'Очищен признак ""Ключевой"" у дополнительного реквизита, отсутствующего в шаблоне';
										|en = 'The ""Key"" check box of the additional attribute missing in the template is cleared'; fa = 'The ""Key"" check box of the additional attribute missing in the template is cleared';
										|it = 'Segno ""Chiave"" cancellato dell''attributo aggiuntivo mancante nel modello';
										|pl = 'Wyczyszczono oznakę ""Kluczowy"" dla dodatkowego atrybutu, którego nie ma w szablonie';
										|tr = 'Numunede olmayan ek öznitelikler için ""Anahtar"" bayrağı silindi'",
						Common.DefaultLanguageCode());
				EndIf;
				WriteLogEvent(
					IntegrationWith1CDocumentManagementCore.EventLogEventName(),
					EventLogLevel.Warning,,
					Rule.Ref,
					MessageText);
					
				NeedEntry = True;
				
				PropsRule.KeyAttribute_ = False;
				
			EndIf;
			
			// A template that prohibits changing the details should not overlap with the rule with other filling options.
			If TemplateForbidModification And FilledInTemplate And PropsRule.Variant <> OptionTemplate() Then
				
				If Not PropsRule.IsAdditionalAttributeDM Then
					MessageText = StrTemplate(NStr("vi = 'Đã đặt phương án điền ""Từ khuôn mẫu"" đối với mục tin %1 bởi vì khuôn mẫu cấm thay đổi';
													|ru = 'Установлен вариант заполнения ""Из шаблона"" для реквизита %1, поскольку шаблон запрещает изменение';
													|en = 'Population option ""From template"" is set for attribute %1 as the template prevents change '; fa = 'Population option ""From template"" is set for attribute %1 as the template prevents change ';
													|it = 'Impostata variante di compilazione ""Da modello"" per l''attributo %1, in quanto il modello non consente modifiche';
													|pl = 'Ustawiono wariant wypełnienia ""Z szablonu"" dla atrybutu %1, ponieważ szablon zabrania zmiany';
													|tr = '""Numuneden"" doldurma seçeneği %1 özniteliği için ayarlandı, çünkü numune değişimi yasaklar'"),
						AttributeName);
				Else
					MessageText = NStr("vi = 'Đã đặt phương án điền ""Từ khuôn mẫu"" đối với mục tin bổ sung bởi vì khuôn mẫu cấm thay đổi';
										|ru = 'Установлен вариант заполнения ""Из шаблона"" для дополнительного реквизита, поскольку шаблон запрещает изменение';
										|en = 'Population option ""From template"" is set for the additional attribute as the template prevents change'; fa = 'Population option ""From template"" is set for the additional attribute as the template prevents change';
										|it = 'Impostata variante di compilazione ""Da modello"" per l''attributo aggiuntivo, in quanto il modello non permette la modifica';
										|pl = 'Ustawiono wariant wypełnienia ""Z szablonu"" dla dodatkowego atrybutu, ponieważ szablon zabrania zmiany';
										|tr = '""Numuneden"" doldurma seçeneği, numune değişikliği yasakladığından ek öznitelik olarak ayarlanmıştır.'");
				EndIf;
				WriteLogEvent(
					IntegrationWith1CDocumentManagementCore.EventLogEventName(),
					EventLogLevel.Warning,,
					Rule.Ref,
					MessageText);
					
				NeedEntry = True;
				
				PropsRule.Variant = OptionTemplate();
				PropsRule.AttributeValueDM = Undefined;
				PropsRule.AttributeNameObjectIS = "";
				
			EndIf;
			
			AttributeNumber = AttributeNumber + 1;
			
		EndDo;
		
		If NeedEntry Then
			Rule.Write();
		EndIf;
		Rule.Unlock();
		
	EndDo;
	
EndProcedure

// Returns the details of the document template.
//
// Parameters:
//   TemplateType - String - the name of the Document Flow object type XDTO (DM<..>DocumentType).
//   TemplateID - String - the name of the Document Flow object type XDTO (DM<..>DocumentType).
//   TemplateForbidModification - Boolean - an implicitly returned value, True, if changing
//     the documents created by the template is prohibited.
//
// Returns:
//   ValueTable:
//     * AttributeNameObjectDM - String - the name of the props in the DO.
//     * TemplateMeaning - Arbitrary - the value of the template's props.
//     * TemplateID - String - id of the reference value of the template's props.
//     * TemplateType - String - the type of the template's props value.
//     * TemplateType - String - the type of the template's props value.
//     * IsAdditionalAttributeDM - Boolean - True if it is an additional prop.
//     * AdditionalAttributeDMID - String - add-on ID. properties BEFORE.
//     * AdditionalAttributeDMType - String - type of add-on. properties BEFORE.
//
Function GetDocumentTemplateDetails(TemplateType, TemplateID, TemplateForbidModification) Export
	
	Attributes = New ValueTable;
	Attributes.Columns.Add("AttributeNameObjectDM", New TypeDescription("String"));
	Attributes.Columns.Add("TemplateMeaning", New TypeDescription("String"));
	Attributes.Columns.Add("TemplateID", New TypeDescription("String"));
	Attributes.Columns.Add("TemplateType", New TypeDescription("String"));
	Attributes.Columns.Add("IsAdditionalAttributeDM", New TypeDescription("Boolean"));
	Attributes.Columns.Add("AdditionalAttributeDMID", New TypeDescription("String"));
	Attributes.Columns.Add("AdditionalAttributeDMType", New TypeDescription("String"));
	Attributes.Columns.Add("Table", New TypeDescription("String"));
	Attributes.Columns.Add("ThisIsTable", New TypeDescription("Boolean"));
	
	If Not ValueIsFilled(TemplateID) Then
		TemplateForbidModification = False;
		Return Attributes;
	EndIf;
	
	// General settings.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, TemplateID, TemplateType);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	
	ListOfObjects.Add(ObjectID);
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	Try
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	Except
		Return Undefined;
	EndTry;
	
	XDTOTemplate = Result.objects[0];
	
	If XDTOTemplate.IsSet("additionalProperties") Then
		AddAttributes = XDTOTemplate.additionalProperties;
	Else
		AddAttributes = New Array;
	EndIf;
	
	If XDTOTemplate.IsSet("blockDerivedDocuments") Then
		TemplateForbidModification = XDTOTemplate.blockDerivedDocuments;
	Else
		TemplateForbidModification = False;
	EndIf;
	
	// General details of templates.
	If TemplateType = "DMIncomingDocumentTemplate"
		Or TemplateType = "DMOutgoingDocumentTemplate"
		Or TemplateType = "DMInternalDocumentTemplate" Then
		AddTemplateDetails_(Proxy, Attributes, "accessLevel", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "comment", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "performanceDate", XDTOTemplate, "performanceTerm");
		AddTemplateDetails_(Proxy, Attributes, "activityMatter", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "responsible", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "organization", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "subdivision", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "summary", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "title", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "project", XDTOTemplate);
	EndIf;
	
	// The template of the incoming document.
	If TemplateType = "DMIncomingDocumentTemplate" Then
		
		AddTemplateDetails_(Proxy, Attributes, "documentType", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "addressee", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "signer", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "correspondent", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "deliveryMethod", XDTOTemplate);
		
	// The template of the outgoing document.
	ElsIf TemplateType = "DMOutgoingDocumentTemplate" Then
		
		AddTemplateDetails_(Proxy, Attributes, "documentType", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "addressee", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "signer", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "correspondent", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "deliveryMethod", XDTOTemplate);
		
	// Internal document template.
	ElsIf TemplateType = "DMInternalDocumentTemplate" Then
		
		AddTemplateDetails_(Proxy, Attributes, "documentType", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "folder", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "correspondent", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "contactPerson", XDTOTemplate);
		AddTemplateDetails_(Proxy, Attributes, "cashFlowItem", XDTOTemplate);
		
	EndIf;
	
	// Additional details.
	For Each AdditionalAttribute5 In AddAttributes Do
		
		NewRow = Attributes.Add();
		NewRow.AttributeNameObjectDM = "";
		NewRow.IsAdditionalAttributeDM = True;
		NewRow.AdditionalAttributeDMID = AdditionalAttribute5.objectID.ID;
		NewRow.AdditionalAttributeDMType = AdditionalAttribute5.objectID.type;
		
		If AdditionalAttribute5.IsSet("propertySimpleValue") Then
			NewRow.TemplateMeaning = AdditionalAttribute5.propertySimpleValue;
		ElsIf AdditionalAttribute5.IsSet("propertyObjectValue") Then
			NewRow.TemplateMeaning = AdditionalAttribute5.propertyObjectValue.name;
			NewRow.TemplateID = AdditionalAttribute5.propertyObjectValue.objectID.ID;
			NewRow.TemplateType = AdditionalAttribute5.propertyObjectValue.objectID.type;
		EndIf;
		
	EndDo;
	
	Return Attributes;
	
EndFunction

// Checks the expression in the built-in language used to fill in the details when transferring data to the DO.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   ObjectIS - Arbitrary - the IP object.
//
Procedure CheckUploadRuleExpression(ComputedExpression, ObjectIS) Export
	
	If TrimAll(ComputedExpression) = "" Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Source", ObjectIS);
	Parameters.Insert("Result", Undefined);
	Parameters.Insert("ResultID", Undefined);
	Parameters.Insert("ResultType", Undefined);
	
	IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
		ComputedExpression,
		Parameters);
	
EndProcedure

// Checks the expression in the built-in language used to fill in the details when receiving data from BEFORE.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   XDTODataObject - XDTODataObject - The XDTO object.
//   ObjectIS - Arbitrary - the IP object.
//
Procedure CheckLoadingRuleExpression(ComputedExpression, XDTODataObject, ObjectIS) Export
	
	If TrimAll(ComputedExpression) = "" Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Source", XDTODataObject);
	Parameters.Insert("Receiver", ObjectIS);
	Parameters.Insert("Result", Undefined);
	
	IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
		ComputedExpression,
		Parameters);
	
EndProcedure

// Checks the expression in the built-in language used to check the applicability of the rule when transferring data to the DO.
//
// Parameters:
//   ApplicabilityConditionOnExport - String - expression in the built-in language.
//   ObjectIS - Arbitrary - the IP object.
//
Procedure CheckApplicabilityConditionExpressionWhenUploading(ApplicabilityConditionOnExport, ObjectIS) Export
	
	If TrimAll(ApplicabilityConditionOnExport) = "" Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Source", ObjectIS);
	Parameters.Insert("Result", True);
	
	IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
		ApplicabilityConditionOnExport,
		Parameters);
	
EndProcedure

// Checks the expression in the built-in language used to check the applicability of the rule when retrieving data from BEFORE.
//
// Parameters:
//   ApplicabilityConditionOnImport - String - expression in the built-in language.
//   XDTODataObject - XDTODataObject - The XDTO object.
//
Procedure CheckApplicabilityConditionExpressionWhenLoading(ApplicabilityConditionOnImport, XDTODataObject) Export
	
	If TrimAll(ApplicabilityConditionOnImport) = "" Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Source", XDTODataObject);
	Parameters.Insert("Result", True);
	
	IntegrationWith1CDocumentManagementCore.ExecuteInSafeMode(
		ApplicabilityConditionOnImport,
		Parameters);
	
EndProcedure

// Checks the integration rule with 1C:Document management.
//
// Parameters:
//   IntegrationRule - CatalogObject.RulesForIntegrationWith1CDocumentManagement
//
Procedure ToCheckRule(IntegrationRule) Export
	
	AttributesOfTheCurrentDocumentKindDM = ObjectAttributesBefore(
		IntegrationRule.ObjectTypeDM,
		New Structure("documentType", DocumentViewFromRule(IntegrationRule)));
	
	AllMapItemDetailsUpTo = ObjectAttributesBefore(IntegrationRule.ObjectTypeDM,,, True);
	
	ObjectAttributesIS = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(IntegrationRule.ObjectTypeIS);
	ObjectMetadataIS = Metadata.FindByFullName(IntegrationRule.ObjectTypeIS);
	ObjectIS = IntegrationWith1CDocumentManagementCore.NewIPObject(IntegrationRule.ObjectTypeIS);
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(Proxy, IntegrationRule.ObjectTypeDM);
	
	ErrorList = New Array;
	
	CheckTheAttributeFillingRulesDM(
		IntegrationRule,
		ObjectIS,
		ObjectMetadataIS,
		ObjectAttributesIS,
		AllMapItemDetailsUpTo,
		ErrorList);
	CheckTheAttributeFillingRulesIS(
		IntegrationRule,
		ObjectIS,
		XDTODataObject,
		ObjectAttributesIS,
		AttributesOfTheCurrentDocumentKindDM,
		AllMapItemDetailsUpTo,
		ErrorList);
	
	Try
		CheckApplicabilityConditionExpressionWhenUploading(
			IntegrationRule.ApplicabilityConditionOnExport,
			ObjectIS);
	Except
		ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorList.Add(
			StrTemplate(
				NStr("vi = 'Lỗi trong điều kiện áp dụng quy tắc để truyền dữ liệu sang 1C:Document Management:
					|Không thể thực hiện biểu thức bằng ngôn ngữ hệ thống do nguyên nhân:
					|""%1""';
					|ru = 'Ошибка в условии применимости правила для передачи данных в 1С:Документооборот:
					|Не удалось выполнить выражение на встроенном языке по причине:
					|""%1""';
					|en = 'An error in the rule applicability condition for transferring data to 1C:Document Management:
					|Cannot execute the expression in 1C:Enterprise language due to:
					|""%1""'; fa = 'An error in the rule applicability condition for transferring data to 1C:Document Management:
					|Cannot execute the expression in 1C:Enterprise language due to:
					|""%1""';
					|it = 'Ошибка в условии применимости правила для передачи данных в 1С:Документооборот:
					|Не удалось выполнить выражение на встроенном языке по причине:
					|""%1""';
					|pl = 'Błąd w warunku przydatności reguły dla przekazania danych w 1С:Document Management:
					|Nie udało się wypełnić wyrażenia w języku wbudowanym z powodu:
					|""%1""';
					|tr = '1C:Document Management''de veri aktarımı kuralının uygulanabilirliği durumunda hata
					|Gömülü dilde ifade şu nedenlerle yürütülemedi:
					|""%1""'"),
						ExceptionText));
	EndTry;
	Try
		CheckApplicabilityConditionExpressionWhenLoading(
			IntegrationRule.ApplicabilityConditionOnImport,
			XDTODataObject);
	Except
		ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorList.Add(
			StrTemplate(
				NStr("vi = 'Lỗi trong điều kiện áp dụng quy tắc để nhận dữ liệu từ 1C:Document Management:
					|Không thể thực hiện biểu thức bằng ngôn ngữ hệ thống do nguyên nhân:
					|""%1""';
					|ru = 'Ошибка в условии применимости правила для получения данных из 1С:Документооборота:
					|Не удалось выполнить выражение на встроенном языке по причине:
					|""%1""';
					|en = 'Error in the rule applicability condition for receiving data from 1C:Document Management:
					|Cannot execute the expression in 1C:Enterprise language due to:
					|""%1""'; fa = 'Error in the rule applicability condition for receiving data from 1C:Document Management:
					|Cannot execute the expression in 1C:Enterprise language due to:
					|""%1""';
					|it = 'Ошибка в условии применимости правила для получения данных из 1С:Документооборота:
					|Не удалось выполнить выражение на встроенном языке по причине:
					|""%1""';
					|pl = 'Błąd w warunku przydatności reguły dla odbioru danych w 1С:Document Management:
					|Nie udało się wypełnić wyrażenia w języku wbudowanym z powodu:
					|""%1""';
					|tr = '1C:Document Management''den veri alma kuralının uygulanabilirliği durumunda hata
					|Gömülü dilde ifade şu nedenlerle yürütülemedi:
					|""%1""'"),
						ExceptionText));
	EndTry;
	
	If ErrorList.Count() > 0 Then
		Raise StrConcat(ErrorList, Chars.LF + Chars.LF);
	EndIf;
	
EndProcedure

// Returns the details of the object TO the specified type, possibly with refinement to the type of document.
//
// Parameters:
//   ObjectTypeDM - String - the name of the Document Flow object type XDTO.
//   Parameters - Structure - clarifying parameters with the property:
//     * documentType - Structure - type of Document management object, with properties:
//         ** ID - String - id of the document type.
//         ** type - String - the XDTO type of the document type.
//         ** name - String - name of the document type.
//   Settings_View - XDTODataObject - an implicitly returned value containing the document type settings.
//   GetAll - Boolean - allows you to return all possible details, regardless of the type of document object.
//
// Returns:
//   ValueTable:
//     * Name - String
//     * Presentation - String
//     * Type - ValueList of String
//     * AdditionalAttribute5 - Boolean
//     * AdditionalAttribute5ID - String
//     * AdditionalAttribute5Type - String
//     * Mandatory - Boolean
//     * ThisIsTable - Boolean
//     * Table - String
//
Function ObjectAttributesBefore(ObjectTypeDM, Parameters = Undefined, Settings_View = Undefined,
		GetAll = False) Export
	
	Attributes = New ValueTable;
	Attributes.Columns.Add("Name", New TypeDescription("String"));
	Attributes.Columns.Add("Presentation", New TypeDescription("String"));
	Attributes.Columns.Add("Type", New TypeDescription("ValueList"));
	Attributes.Columns.Add("AdditionalAttribute5", New TypeDescription("Boolean"));
	Attributes.Columns.Add("AdditionalAttribute5ID", New TypeDescription("String"));
	Attributes.Columns.Add("AdditionalAttribute5Type", New TypeDescription("String"));
	Attributes.Columns.Add("Mandatory", New TypeDescription("Boolean"));
	Attributes.Columns.Add("ThisIsTable", New TypeDescription("Boolean"));
	Attributes.Columns.Add("Table", New TypeDescription("String"));
	Attributes.Columns.Add("TableForSorting", New TypeDescription("String"));
	Attributes.Columns.Add("Order", New TypeDescription("Number"));
	
	// General settings.
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
	FieldsReceived = Query.columnSet; // XDTOList
	
	Query.type = ObjectTypeDM;
	FieldsReceived.Add("additionalProperties");
	FieldsReceived.Add("documentTypeEnabled");
	FieldsReceived.Add("accessLevelEnabled");
	FieldsReceived.Add("activityMatterEnabled");
	FieldsReceived.Add("organizationEnabled");
	FieldsReceived.Add("statusEnabled");
	FieldsReceived.Add("statusChangeEnabled");
	
	// Projects.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		FieldsReceived.Add("projectsEnabled");
	EndIf;
	
	BatchRequestAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3");
	If BatchRequestAvailable Then
		PackageQueries = New Array;
		PackageQueries.Add(Query);
	Else // Only sequential calls.
		ResultDocument_ = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	EndIf;
	
	If Parameters <> Undefined
			And Parameters.Property("documentType")
			And Parameters.documentType <> Undefined Then
		
		// Settings by document type.
		ObjectToGetFromTO = New Structure("ID, Type", Parameters.documentType.ID, Parameters.documentType.type);
		Query = IntegrationWith1CDocumentManagementCore.GetRequestObjects(
			Proxy,
			CommonClientServer.ValueInArray(ObjectToGetFromTO));
		
		If BatchRequestAvailable Then
			
			PackageQueries.Add(Query);
			
			ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
				Proxy,
				PackageQueries);
			
			ResultDocument_ = ResponseToPackageRequests.responses[0];
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultDocument_);
			TypesSettings = ResultDocument_;
			AddAttributes = ResultDocument_.additionalProperties;
			
			ResultsFromSettings = ResponseToPackageRequests.responses[1];
			Try
				IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultsFromSettings);
				YouNeedToGetTypeSettings = False;
			Except // Perhaps this type of document is no longer in the DO.
				YouNeedToGetTypeSettings = True;
				IntegrationWith1CDocumentManagementCore.WriteWarning(
					StrTemplate(NStr("vi = 'Không tìm thấy trong 1C:Document Management có dạng văn bản đã tồn tại từ trước %1';
									|ru = 'Не найден в 1С:Документообороте ранее существовавший вид документа %1';
									|en = 'The earlier existing %1 document kind was not found in 1C:Document Management'; fa = 'The earlier existing %1 document kind was not found in 1C:Document Management';
									|it = 'In 1C:Document Management non è stato trovato il tipo di documento %1 precedentemente esistente';
									|pl = 'W 1С:Document Management nie znaleziono wcześniej istniejącego rodzaju dokumentu %1';
									|tr = '1C:Document Management''de önceden var olan belge türü bulunamadı %1'"),
					Parameters.documentType.ID));
			EndTry;
			
		Else
			ResultsFromSettings = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			YouNeedToGetTypeSettings = False;
			
		EndIf;
		
		If Not YouNeedToGetTypeSettings Then
			
			Settings_View = ResultsFromSettings.objects[0];
			
			ResultDocument_.documentType = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				ObjectTypeDM + "Type");
			ResultDocument_.documentType.name = Parameters.documentType.name;
			ResultDocument_.documentType.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				Parameters.documentType.ID,
				Parameters.documentType.type);
			
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMGetObjectAdditionalPropertiesRequest");
			Query.object = ResultDocument_;
			TypesSettings = ResultDocument_;
			
			Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
			AddAttributes = Result.additionalProperties;
			
		EndIf;
		
	Else // The type of document is unknown.
		
		YouNeedToGetTypeSettings = True;
		
	EndIf;
	
	If YouNeedToGetTypeSettings Then
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetNewObjectRequest");
		FieldsReceived = Query.columnSet; // XDTOList
		
		Query.type = ObjectTypeDM;
		FieldsReceived.Add("additionalProperties");
		FieldsReceived.Add("documentTypeEnabled");
		FieldsReceived.Add("accessLevelEnabled");
		FieldsReceived.Add("activityMatterEnabled");
		FieldsReceived.Add("organizationEnabled");
		FieldsReceived.Add("statusEnabled");
		FieldsReceived.Add("statusChangeEnabled");
		
		ResultDocument_ = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		
	EndIf;
	
	If Not BatchRequestAvailable Or YouNeedToGetTypeSettings Then
		
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultDocument_);
		TypesSettings = ResultDocument_;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(ResultDocument_, "additionalProperties") Then
			AddAttributes = ResultDocument_.additionalProperties;
		Else
			AddAttributes = New Array;
		EndIf;
		
		Settings_View = Undefined;
		
	EndIf;
	
	// Standard Attributes.
	AddAttribute(Attributes, "deletionMark", NStr("vi = 'Đánh dấu xóa';
													|ru = 'Пометка удаления';
													|en = 'Deletion mark'; fa = 'علامت حذف';
													|it = 'Пометка удаления';
													|pl = 'Zaznaczenie usunięcia';
													|tr = 'Silme işareti'"), "Boolean");
	
	// Incoming document.
	If ObjectTypeDM = "DMIncomingDocument" Then
		
		If GetAll Or TypesSettings.documentTypeEnabled = True Then
			AddAttribute(Attributes, "documentType", NStr("vi = 'Dạng chứng từ';
															|ru = 'Вид документа';
															|en = 'Document kind'; fa = 'نوع سند';
															|it = 'Tipologia di documento';
															|pl = 'Rodzaj dokumentu';
															|tr = 'Belge türü'"), "DMIncomingDocumentType", True);
		EndIf;
		
		AddAttribute(Attributes, "correspondent", NStr("vi = 'Người gửi';
														|ru = 'Отправитель';
														|en = 'Sender'; fa = 'فرستنده';
														|it = 'Отправитель';
														|pl = 'Sender';
														|tr = 'Gönderici'"), "DMCorrespondent", True);
		AddAttribute(Attributes, "externalNumber", NStr("vi = 'Số người gửi';
														|ru = '№ отправителя';
														|en = 'Sender No.'; fa = 'Sender No.';
														|it = '№ mittente';
														|pl = 'nr nadawcy';
														|tr = 'Gönderen №'"), "String");
		AddAttribute(Attributes, "externalDate", NStr("vi = 'Ngày gửi';
														|ru = 'Дата отправителя';
														|en = 'Sender date'; fa = 'تاریخ فرستنده';
														|it = 'Data invio';
														|pl = 'Data nadawcy';
														|tr = 'Gönderen tarihi'"), "Date");
		
		If GetAll Or TypesSettings.organizationEnabled = True Then
			AddAttribute(Attributes, "organization", NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Организация';
															|pl = 'Firma';
															|tr = 'İş yeri'"), "DMOrganization", True);
		EndIf;
		
		If GetAll Or Settings_View = Undefined Or Settings_View.sumEnabled = True Then
			AddAttribute(Attributes, "sum", NStr("vi = 'Tổng số';
												|ru = 'Сумма';
												|en = 'Amount'; fa = 'مبلغ';
												|it = 'Сумма';
												|pl = 'Wartość';
												|tr = 'Tutar'"), "Number");
			AddAttribute(Attributes, "currency", NStr("vi = 'Tiền tệ';
														|ru = 'Валюта';
														|en = 'Currency'; fa = 'ارز';
														|it = 'Валюта';
														|pl = 'Waluta';
														|tr = 'Para birimi'"), "DMCurrency");
		EndIf;
		
		AddAttribute(Attributes, "title", NStr("vi = 'Tên gọi';
												|ru = 'Наименование';
												|en = 'Description'; fa = 'شرح';
												|it = 'Наименование';
												|pl = 'Description';
												|tr = 'Tanım'"), "String", True);
		AddAttribute(Attributes, "summary", NStr("vi = 'Nội dung';
												|ru = 'Содержание';
												|en = 'Content'; fa = 'محتوا';
												|it = 'Содержание';
												|pl = 'Content';
												|tr = 'İçerik'"), "String");
		AddAttribute(Attributes, "regNumber", NStr("vi = 'Số đăng ký';
													|ru = 'Регистрационный номер';
													|en = 'Registration number'; fa = 'شماره ثبت';
													|it = 'Numero di registrazione';
													|pl = 'Numer rejestracyjny';
													|tr = 'Kayıt numarası'"), "String");
		AddAttribute(Attributes, "regDate", NStr("vi = 'Ngày đăng ký';
												|ru = 'Дата регистрации';
												|en = 'Registration date'; fa = 'تاریخ ثبت';
												|it = 'Data di registrazione';
												|pl = 'Data rejestracji';
												|tr = 'Kayıt tarihi'"), "Date");
		
		AddAttribute(Attributes, "signer", NStr("vi = 'Người ký';
												|ru = 'Подписал';
												|en = 'Signed by'; fa = 'امضاشده توسط';
												|it = 'Подписал';
												|pl = 'Signed by';
												|tr = 'İmzaladı'"), "DMContactPerson");
		AddAttribute(Attributes, "addressee", NStr("vi = 'Người nhận';
													|ru = 'Адресат';
													|en = 'Addressee'; fa = 'مخاطب';
													|it = 'Адресат';
													|pl = 'Addressee';
													|tr = 'Alıcı'"), "DMUser");
		AddAttribute(Attributes, "subdivision", NStr("vi = 'Bộ phận';
													|ru = 'Подразделение';
													|en = 'Business unit'; fa = 'Business unit';
													|it = 'Подразделение';
													|pl = 'Dział';
													|tr = 'Departman'"), "DMSubdivision");
		
		If GetAll Or Settings_View = Undefined Or Settings_View.performanceDateEnabled = True Then
			AddAttribute(Attributes, "performanceDate", NStr("vi = 'Thời hạn thực hiện';
															|ru = 'Срок исполнения';
															|en = 'Due date'; fa = 'تاریخ سررسید';
															|it = 'Tempo di esecuzione';
															|pl = 'Data realizacji';
															|tr = 'Son tarih'"), "Date");
		EndIf;
		
		If GetAll Or TypesSettings.accessLevelEnabled  = True Then
			AddAttribute(Attributes, "accessLevel", NStr("vi = 'Độ mật';
														|ru = 'Гриф доступа';
														|en = 'Access label '; fa = 'Access label ';
														|it = 'Dicitura di accesso';
														|pl = 'Poziom dostępu';
														|tr = 'Erişim etiketi'"), "DMAccessLevel", True);
		EndIf;
		
		If GetAll Or TypesSettings.activityMatterEnabled = True Then
			AddAttribute(Attributes, "activityMatter", NStr("vi = 'Vấn đề nghiệp vụ';
															|ru = 'Вопрос деятельности';
															|en = 'Activity issue'; fa = 'موضوع فعالیت';
															|it = 'Problema di attività';
															|pl = 'Kwestia działalności';
															|tr = 'Faaliyet sorusu'"), "DMActivityMatter", True);
		EndIf;
		
		// Projects.
		If GetAll Or (IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP")
				And TypesSettings.projectsEnabled = True) Then
			AddAttribute(Attributes, "project", NStr("vi = 'Dự án';
													|ru = 'Проект';
													|en = 'Project'; fa = 'پروژه';
													|it = 'Проект';
													|pl = 'Project';
													|tr = 'Proje'"), "DMProject");
		EndIf;
		
		AddAttribute(Attributes, "deliveryMethod",  NStr("vi = 'Phương thức nhận';
														|ru = 'Способ получения';
														|en = 'Receipt method'; fa = 'روش دریافت';
														|it = 'Metodo di ricezione';
														|pl = 'Sposób odbioru';
														|tr = 'Alma yöntemi'"), "DMDeliveryMethod");
		
		AddAttribute(Attributes, "comment", NStr("vi = 'Diễn giải';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Comment';
												|tr = 'Yorum'"), "String");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Responsible person'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMUser");
		
	// Outgoing document.
	ElsIf ObjectTypeDM = "DMOutgoingDocument" Then
		
		If GetAll Or TypesSettings.documentTypeEnabled = True Then
			AddAttribute(Attributes, "documentType", NStr("vi = 'Dạng chứng từ';
															|ru = 'Вид документа';
															|en = 'Document kind'; fa = 'نوع سند';
															|it = 'Tipologia di documento';
															|pl = 'Rodzaj dokumentu';
															|tr = 'Belge türü'"), "DMOutgoingDocumentType", True);
		EndIf;
			
		AddAttribute(Attributes, "correspondent", NStr("vi = 'Người nhận';
														|ru = 'Получатель';
														|en = 'Recipient'; fa = 'گیرنده';
														|it = 'Получатель';
														|pl = 'Odbiorca';
														|tr = 'Alıcı'"), "DMCorrespondent", True);
		
		If GetAll Or Settings_View = Undefined Or Settings_View.externalNumberEnabled = True Then
			AddAttribute(Attributes, "externalNumber", NStr("vi = 'Số người nhận';
															|ru = '№ получателя';
															|en = 'Recipient No.'; fa = 'شماره گیرنده';
															|it = '№ destinatario';
															|pl = 'nr odbiorcy';
															|tr = 'Alıcı №'"), "String");
			AddAttribute(Attributes, "externalDate", NStr("vi = 'Ngày người nhận';
															|ru = 'Дата получателя';
															|en = 'Recipient date '; fa = 'تاریخ گیرنده';
															|it = 'Data destinatario';
															|pl = 'Data odbioru';
															|tr = 'Alıcı tarihi'"), "Date");
		EndIf;
		
		If GetAll Or TypesSettings.OrganizationEnabled = True Then
			AddAttribute(Attributes, "organization", NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Организация';
															|pl = 'Firma';
															|tr = 'İş yeri'"), "DMOrganization", True);
		EndIf;
		
		If GetAll Or Settings_View = Undefined Or Settings_View.sumEnabled = True Then
			AddAttribute(Attributes, "sum", NStr("vi = 'Tổng số';
												|ru = 'Сумма';
												|en = 'Amount'; fa = 'مبلغ';
												|it = 'Сумма';
												|pl = 'Wartość';
												|tr = 'Tutar'"), "Number");
			AddAttribute(Attributes, "currency", NStr("vi = 'Tiền tệ';
														|ru = 'Валюта';
														|en = 'Currency'; fa = 'ارز';
														|it = 'Валюта';
														|pl = 'Waluta';
														|tr = 'Para birimi'"), "DMCurrency");
		EndIf;
		
		AddAttribute(Attributes, "title", NStr("vi = 'Tiêu đề';
												|ru = 'Заголовок';
												|en = 'Title'; fa = 'عنوان';
												|it = 'Заголовок';
												|pl = 'Title';
												|tr = 'Başlık'"), "String", True);
		AddAttribute(Attributes, "summary", NStr("vi = 'Nội dung';
												|ru = 'Содержание';
												|en = 'Content'; fa = 'محتوا';
												|it = 'Содержание';
												|pl = 'Content';
												|tr = 'İçerik'"), "String");
		AddAttribute(Attributes, "regNumber", NStr("vi = 'Số đăng ký';
													|ru = 'Регистрационный номер';
													|en = 'Registration number'; fa = 'شماره ثبت';
													|it = 'Numero di registrazione';
													|pl = 'Numer rejestracyjny';
													|tr = 'Kayıt numarası'"), "String");
		AddAttribute(Attributes, "regDate", NStr("vi = 'Ngày đăng ký';
												|ru = 'Дата регистрации';
												|en = 'Registration date'; fa = 'تاریخ ثبت';
												|it = 'Data di registrazione';
												|pl = 'Data rejestracji';
												|tr = 'Kayıt tarihi'"), "Date");
		
		AddAttribute(Attributes, "addressee", NStr("vi = 'Người nhận';
													|ru = 'Адресат';
													|en = 'Addressee'; fa = 'مخاطب';
													|it = 'Адресат';
													|pl = 'Addressee';
													|tr = 'Alıcı'"), "DMContactPerson");
		AddAttribute(Attributes, "sent", NStr("vi = 'Đã gửi';
												|ru = 'Отправлен';
												|en = 'Sent'; fa = 'ارسال‌شده';
												|it = 'Отправлен';
												|pl = 'Sent';
												|tr = 'Gönderildi'"), "Boolean");
		AddAttribute(Attributes, "sendDate", NStr("vi = 'Ngày gửi';
													|ru = 'Дата отправки';
													|en = 'Date sent'; fa = 'تاریخ ارسال';
													|it = 'Data di spedizione';
													|pl = 'Data wysłania';
													|tr = 'Gönderilme tarihi'"), "Date");
		
		AddAttribute(Attributes, "signer", NStr("vi = 'Người ký';
												|ru = 'Подписал';
												|en = 'Signed by'; fa = 'امضاشده توسط';
												|it = 'Подписал';
												|pl = 'Signed by';
												|tr = 'İmzaladı'"), "DMUser");
		AddAttribute(Attributes, "author", NStr("vi = 'Người soạn';
												|ru = 'Подготовил';
												|en = 'Prepared by'; fa = 'تهیه‌شده توسط';
												|it = 'Подготовил';
												|pl = 'Prepared by';
												|tr = 'Hazırlayan'"), "DMUser");
		AddAttribute(Attributes, "subdivision", NStr("vi = 'Bộ phận';
													|ru = 'Подразделение';
													|en = 'Business unit'; fa = 'Business unit';
													|it = 'Подразделение';
													|pl = 'Dział';
													|tr = 'Departman'"), "DMSubdivision");
		
		If GetAll Or Settings_View = Undefined Or Settings_View.performanceDateEnabled = True Then
			AddAttribute(Attributes, "performanceDate", NStr("vi = 'Thời hạn thực hiện';
															|ru = 'Срок исполнения';
															|en = 'Due date'; fa = 'تاریخ سررسید';
															|it = 'Tempo di esecuzione';
															|pl = 'Data realizacji';
															|tr = 'Son tarih'"), "Date");
		EndIf;
		
		If GetAll Or TypesSettings.accessLevelEnabled = True Then
			AddAttribute(Attributes, "accessLevel", NStr("vi = 'Độ mật';
														|ru = 'Гриф доступа';
														|en = 'Access label '; fa = 'Access label ';
														|it = 'Dicitura di accesso';
														|pl = 'Poziom dostępu';
														|tr = 'Erişim etiketi'"), "DMAccessLevel", True);
		EndIf;
		
		If GetAll Or TypesSettings.activityMatterEnabled = True Then
			AddAttribute(Attributes, "activityMatter", NStr("vi = 'Vấn đề nghiệp vụ';
															|ru = 'Вопрос деятельности';
															|en = 'Activity issue'; fa = 'موضوع فعالیت';
															|it = 'Problema di attività';
															|pl = 'Kwestia działalności';
															|tr = 'Faaliyet sorusu'"), "DMActivityMatter", True);
		EndIf;
		
		// Projects.
		If GetAll Or (IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP")
				And TypesSettings.projectsEnabled = True) Then
			AddAttribute(Attributes, "project", NStr("vi = 'Dự án';
													|ru = 'Проект';
													|en = 'Project'; fa = 'پروژه';
													|it = 'Проект';
													|pl = 'Project';
													|tr = 'Proje'"), "DMProject");
		EndIf;
		
		AddAttribute(Attributes, "deliveryMethod", NStr("vi = 'Cách gửi';
														|ru = 'Способ отправки';
														|en = 'Sending method'; fa = 'روش ارسال';
														|it = 'Metodo di spedizione';
														|pl = 'Sposób wysyłki';
														|tr = 'Gönderme yöntemi'"), "DMDeliveryMethod");
		AddAttribute(Attributes, "comment", NStr("vi = 'Diễn giải';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Comment';
												|tr = 'Yorum'"), "String");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Responsible person'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMUser");
		
	// Internal document.
	ElsIf ObjectTypeDM = "DMInternalDocument" Then
		
		IsRequestForPayment = False;
		If Settings_View <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertyExists(Settings_View, "isAPaymentRequest")
				And Settings_View.isAPaymentRequest = True Then
			IsRequestForPayment = True;
		EndIf;
		
		KeepRecordsOfParties = False;
		If Settings_View <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertySet(Settings_View, "partiesEnabled")
				And Settings_View.partiesEnabled = True Then
			KeepRecordsOfParties = True;
		EndIf;
		
		If GetAll Or TypesSettings.documentTypeEnabled = True Then
			AddAttribute(Attributes, "documentType", NStr("vi = 'Dạng chứng từ';
															|ru = 'Вид документа';
															|en = 'Document kind'; fa = 'نوع سند';
															|it = 'Tipologia di documento';
															|pl = 'Rodzaj dokumentu';
															|tr = 'Belge türü'"), "DMInternalDocumentType", True);
		EndIf;
		
		AddAttribute(Attributes, "folder", NStr("vi = 'Thư mục';
												|ru = 'Папка';
												|en = 'Folder'; fa = 'پوشه';
												|it = 'Папка';
												|pl = 'Folder';
												|tr = 'Klasör'"), "DMInternalDocumentFolder", True);
		
		If GetAll Or (Settings_View = Undefined
				Or (Settings_View.Properties().Get("addresseeEnabled") <> Undefined
					And Settings_View.addresseeEnabled = True)) Then
			AddAttribute(Attributes, "addressee", NStr("vi = 'Người nhận';
														|ru = 'Адресат';
														|en = 'Addressee'; fa = 'مخاطب';
														|it = 'Адресат';
														|pl = 'Addressee';
														|tr = 'Alıcı'"), "DMUser", True);
		EndIf;
		
		If GetAll
				Or (TypesSettings.organizationEnabled = True
					And (Settings_View = Undefined
						Or Settings_View.Properties().Get("organizationEnabled") = Undefined
						Or Settings_View.organizationEnabled = True)) Then
			If IsRequestForPayment Then
				TitleOrganization = NStr("vi = 'Người nộp';
										|ru = 'Плательщик';
										|en = 'Payer'; fa = 'پرداخت‌کننده';
										|it = 'Плательщик';
										|pl = 'Payer';
										|tr = 'Ödeyen'");
			Else
				TitleOrganization = NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Организация';
										|pl = 'Firma';
										|tr = 'İş yeri'");
			EndIf;
			AddAttribute(Attributes, "organization", TitleOrganization, "DMOrganization",
				IsRequestForPayment Or Not KeepRecordsOfParties);
		EndIf;
		
		If GetAll Or IsRequestForPayment Then
			AddAttribute(Attributes, "recipient", NStr("vi = 'Người nhận';
														|ru = 'Получатель';
														|en = 'Recipient'; fa = 'گیرنده';
														|it = 'Получатель';
														|pl = 'Odbiorca';
														|tr = 'Alıcı'"), "DMParty", True);
		EndIf;
		
		If GetAll Or Settings_View = Undefined Or Settings_View.sumEnabled = True Then
			AddAttribute(Attributes, "sum", NStr("vi = 'Tổng số';
												|ru = 'Сумма';
												|en = 'Amount'; fa = 'مبلغ';
												|it = 'Сумма';
												|pl = 'Wartość';
												|tr = 'Tutar'"), "Number");
			If GetAll
					Or IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.8.1.CORP") Then
				AddAttribute(Attributes, "VAT", NStr("vi = 'Trong đó, thuế GTGT';
													|ru = 'В т.ч. НДС';
													|en = 'Including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
													|it = 'Iva inclusa';
													|pl = 'w tym VAT';
													|tr = 'KDV dahil'"), "Number");
			EndIf;
			AddAttribute(Attributes, "currency", NStr("vi = 'Tiền tệ';
														|ru = 'Валюта';
														|en = 'Currency'; fa = 'ارز';
														|it = 'Валюта';
														|pl = 'Waluta';
														|tr = 'Para birimi'"), "DMCurrency");
		EndIf;
		
		AddAttribute(Attributes, "title", NStr("vi = 'Tiêu đề';
												|ru = 'Заголовок';
												|en = 'Title'; fa = 'عنوان';
												|it = 'Заголовок';
												|pl = 'Title';
												|tr = 'Başlık'"), "String", True);
		AddAttribute(Attributes, "summary", NStr("vi = 'Nội dung';
												|ru = 'Содержание';
												|en = 'Content'; fa = 'محتوا';
												|it = 'Содержание';
												|pl = 'Content';
												|tr = 'İçerik'"), "String");
		AddAttribute(Attributes, "regNumber", NStr("vi = 'Số đăng ký';
													|ru = 'Регистрационный номер';
													|en = 'Registration number'; fa = 'شماره ثبت';
													|it = 'Numero di registrazione';
													|pl = 'Numer rejestracyjny';
													|tr = 'Kayıt numarası'"), "String");
		AddAttribute(Attributes, "regDate", NStr("vi = 'Ngày đăng ký';
												|ru = 'Дата регистрации';
												|en = 'Registration date'; fa = 'تاریخ ثبت';
												|it = 'Data di registrazione';
												|pl = 'Data rejestracji';
												|tr = 'Kayıt tarihi'"), "Date");
		
		AddAttribute(Attributes, "signer", NStr("vi = 'Người duyệt';
												|ru = 'Утвердил';
												|en = 'Approved'; fa = 'تأییدشده';
												|it = 'Утвердил';
												|pl = 'Approved';
												|tr = 'Onaylandı'"), "DMUser");
		AddAttribute(Attributes, "author", NStr("vi = 'Người soạn';
												|ru = 'Подготовил';
												|en = 'Prepared by'; fa = 'تهیه‌شده توسط';
												|it = 'Подготовил';
												|pl = 'Prepared by';
												|tr = 'Hazırlayan'"), "DMUser");
		AddAttribute(Attributes, "subdivision", NStr("vi = 'Bộ phận';
													|ru = 'Подразделение';
													|en = 'Business unit'; fa = 'Business unit';
													|it = 'Подразделение';
													|pl = 'Dział';
													|tr = 'Departman'"), "DMSubdivision");
		
		If GetAll Or (KeepRecordsOfParties And Not IsRequestForPayment)
				Or Settings_View = Undefined
				Or Settings_View.correspondentEnabled = True Then
			
			If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
				TermCounterparty = NStr("vi = 'Cơ sở thông tin trao đổi';
										|ru = 'Корреспондент';
										|en = 'Peer infobase'; fa = 'پایگاه اطلاعات همتا';
										|it = 'Корреспондент';
										|pl = 'Korespondent';
										|tr = 'Muhabir'");
			Else
				TermCounterparty = NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Контрагент';
										|pl = 'Kontrahent';
										|tr = 'Cari hesap'");
			EndIf;
			AddAttribute(
				Attributes,
				"correspondent",
				TermCounterparty,
				"DMCorrespondent",
				?(IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP"), False, True));
			AddAttribute(Attributes, "contactPerson", NStr("vi = 'Người liên hệ';
															|ru = 'Контактное лицо';
															|en = 'Contact person'; fa = 'شخص تماس';
															|it = 'Contatto';
															|pl = 'Osoba do kontaktu';
															|tr = 'İrtibat kişisi'"), "DMContactPerson");
			
		EndIf;
		
		If GetAll
				Or (IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP")
					And (Settings_View = Undefined Or Settings_View.correspondentEnabled = True)) Then
			
			// The table part is Counterparties.
			AddTable(Attributes, "correspondentRows.rows", NStr("vi = 'Đối tác';
																|ru = 'Контрагенты';
																|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
																|it = 'Контрагенты';
																|pl = 'Kontrahenci';
																|tr = 'Cari hesaplar'"));
			AddTableDetails(Attributes,
				"correspondentRows.rows", "correspondent", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Контрагент';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'"), "DMCorrespondent", True);
			AddTableDetails(Attributes,
				"correspondentRows.rows", "contact", NStr("vi = 'Người liên hệ';
															|ru = 'Контактное лицо';
															|en = 'Contact person'; fa = 'شخص تماس';
															|it = 'Contatto';
															|pl = 'Osoba do kontaktu';
															|tr = 'İrtibat kişisi'"), "DMContactPerson");
			AddTableDetails(Attributes,
				"correspondentRows.rows",
				"signedFromTheCorrespondent", NStr("vi = 'Đã ký từ đối tác';
													|ru = 'Подписал от контрагента';
													|en = 'Signed on behalf of a counterparty'; fa = 'امضاشده از طرف طرف حساب';
													|it = 'Firmato dalla controparte';
													|pl = 'Podpisał od kontrahenta';
													|tr = 'Cari hesaptan imzalandı'"), "DMContactPerson");
			
		EndIf;
		
		If GetAll Or Settings_View = Undefined Or Settings_View.durationEnabled = True Then
			AddAttribute(Attributes,
				"beginDate", NStr("vi = 'Ngày có hiệu lực';
									|ru = 'Дата начала действия';
									|en = 'Certificate start date'; fa = 'تاریخ شروع گواهی';
									|it = 'Data di inizio validità';
									|pl = 'Data rozpoczęcia działania';
									|tr = 'Geçerlilik başlangıç tarihi'"), "Date");
			AddAttribute(Attributes,
				"endDate", NStr("vi = 'Ngày kết thúc hiệu lực';
								|ru = 'Дата окончания действия';
								|en = 'Certificate end date'; fa = 'تاریخ پایان گواهی';
								|it = 'Data di fine validità';
								|pl = 'Data wygaśnięcia';
								|tr = 'Geçerlilik bitiş tarihi'"), "Date");
			AddAttribute(Attributes,
				"openEnded", NStr("vi = 'Không thời hạn';
									|ru = 'Бессрочный';
									|en = 'Permanent'; fa = 'دائمی';
									|it = 'Бессрочный';
									|pl = 'Permanent';
									|tr = 'Süresiz'"), "Boolean");
			AddAttribute(Attributes,
				"prolongationProcedure", NStr("vi = 'Trình tự gia hạn';
												|ru = 'Порядок продления';
												|en = 'Extension procedure'; fa = 'رویه تمدید';
												|it = 'Ordine di proroga';
												|pl = 'Tryb przedłużenia';
												|tr = 'Uzatma prosedürü'"), "DMProlongationProcedure");
		EndIf;
		
		If GetAll Or TypesSettings.accessLevelEnabled = True Then
			AddAttribute(Attributes, "accessLevel", NStr("vi = 'Độ mật';
														|ru = 'Гриф доступа';
														|en = 'Access label '; fa = 'Access label ';
														|it = 'Dicitura di accesso';
														|pl = 'Poziom dostępu';
														|tr = 'Erişim etiketi'"), "DMAccessLevel", True);
		EndIf;
		
		If GetAll Or TypesSettings.activityMatterEnabled = True Then
			AddAttribute(Attributes, "activityMatter", NStr("vi = 'Vấn đề nghiệp vụ';
															|ru = 'Вопрос деятельности';
															|en = 'Activity issue'; fa = 'موضوع فعالیت';
															|it = 'Problema di attività';
															|pl = 'Kwestia działalności';
															|tr = 'Faaliyet sorusu'"), "DMActivityMatter", True);
		EndIf;
		
		// Projects.
		If GetAll Or (IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP")
				And TypesSettings.projectsEnabled = True) Then
			AddAttribute(Attributes, "project", NStr("vi = 'Dự án';
													|ru = 'Проект';
													|en = 'Project'; fa = 'پروژه';
													|it = 'Проект';
													|pl = 'Project';
													|tr = 'Proje'"), "DMProject");
		EndIf;
		
		If GetAll Or Settings_View = Undefined Or Settings_View.performanceDateEnabled = True Then
			AddAttribute(Attributes, "performanceDate", NStr("vi = 'Thời hạn thực hiện';
															|ru = 'Срок исполнения';
															|en = 'Due date'; fa = 'تاریخ سررسید';
															|it = 'Tempo di esecuzione';
															|pl = 'Data realizacji';
															|tr = 'Son tarih'"), "Date");
		EndIf;
		
		AddAttribute(Attributes, "comment", NStr("vi = 'Diễn giải';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Comment';
												|tr = 'Yorum'"), "String");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Responsible person'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMUser");
		
		// Amounts under DDS items.
		If GetAll Or (Settings_View <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertySet(Settings_View, "cashFlowDetailsEnabled")
				And Settings_View.cashFlowDetailsEnabled = True) Then
			
			AddTable(Attributes, "cashFlowRows.rows", NStr("vi = 'Dạng lưu chuyển tiền tệ';
															|ru = 'Статьи движения денежных средств';
															|en = 'Cash flow items'; fa = 'اقلام جریان وجوه نقد';
															|it = 'Voci flusso di denaro';
															|pl = 'Pozycje przepływów środków pieniężnych';
															|tr = 'Nakit akışı öğeleri'"));
			AddTableDetails(Attributes, "cashFlowRows.rows", "item", NStr("vi = 'Dạng';
																			|ru = 'Статья';
																			|en = 'Item'; fa = 'قلم';
																			|it = 'Статья';
																			|pl = 'Pozycja';
																			|tr = 'Kalem'"), "DMCashFlowItem", True);
			AddTableDetails(Attributes, "cashFlowRows.rows", "total", NStr("vi = 'Tổng số';
																			|ru = 'Сумма';
																			|en = 'Amount'; fa = 'مبلغ';
																			|it = 'Сумма';
																			|pl = 'Wartość';
																			|tr = 'Tutar'"), "Number");
			AddTableDetails(Attributes, "cashFlowRows.rows", "VAT", NStr("vi = 'Thuế GTGT';
																		|ru = 'Сумма НДС';
																		|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
																		|it = 'Importo IVA';
																		|pl = 'Wartość VAT';
																		|tr = 'KDV tutarı'"), "Number");
			
		EndIf;
		
		// The tabular part of the Goods.
		If GetAll Or (Settings_View <> Undefined
				And IntegrationWith1CDocumentManagementCore.PropertySet(Settings_View, "productRowsEnabled")
				And Settings_View.productRowsEnabled = True) Then
			
			AddTable(Attributes, "productRows.rows", NStr("vi = 'Hàng hóa và dịch vụ';
															|ru = 'Товары и услуги';
															|en = 'Goods and services'; fa = 'کالاها و خدمات';
															|it = 'Articoli e servizi';
															|pl = 'Towary i usługi';
															|tr = 'Ürünler ve hizmetler'"));
			
			AddTableDetails(Attributes,
				"productRows.rows", "product", NStr("vi = 'Hàng hóa, dịch vụ';
													|ru = 'Товар, услуга';
													|en = 'Good, service'; fa = 'کالا، خدمت';
													|it = 'Articolo, servizio';
													|pl = 'Towar, usługa';
													|tr = 'Ürün, hizmet'"), "DMProduct");
			
			AddTableDetails(Attributes,
				"productRows.rows", "price", NStr("vi = 'Đơn giá';
													|ru = 'Цена';
													|en = 'Price'; fa = 'قیمت';
													|it = 'Цена';
													|pl = 'Cena';
													|tr = 'Fiyat'"), "Number");
			
			AddTableDetails(Attributes,
				"productRows.rows", "quantity", NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Количество';
													|pl = 'Ilość';
													|tr = 'Miktar'"), "Number");
			
			AddTableDetails(Attributes,
				"productRows.rows", "measurementUnit", NStr("vi = 'Đơn vị tính';
															|ru = 'Единица измерения';
															|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
															|it = 'Unità di misura';
															|pl = 'Jednosta miary';
															|tr = 'Ölçü birimi'"), "DMMeasurementUnit");
			
			AddTableDetails(Attributes,
				"productRows.rows", "VATRate", NStr("vi = 'Thuế suất GTGT';
													|ru = 'Ставка НДС';
													|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
													|it = 'Aliquota IVA';
													|pl = 'Stawka VAT';
													|tr = 'KDV oranı'"), "DMVATRate");
			
			AddTableDetails(Attributes,
				"productRows.rows", "VAT", NStr("vi = 'Thuế GTGT';
												|ru = 'Сумма НДС';
												|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
												|it = 'Importo IVA';
												|pl = 'Wartość VAT';
												|tr = 'KDV tutarı'"), "Number");
			
			AddTableDetails(Attributes,
				"productRows.rows", "total", NStr("vi = 'Tổng số';
													|ru = 'Сумма';
													|en = 'Amount'; fa = 'مبلغ';
													|it = 'Сумма';
													|pl = 'Wartość';
													|tr = 'Tutar'"), "Number");
			
		EndIf;
		
		// The tabular part of the Side.
		If GetAll Or (IsRequestForPayment = False And KeepRecordsOfParties) Then
			
			AddTable(Attributes, "partyRows.rows", NStr("vi = 'Các bên';
														|ru = 'Стороны';
														|en = 'Parties'; fa = 'طرفین';
														|it = 'Стороны';
														|pl = 'Parties';
														|tr = 'Taraflar'"));
			
			AddTableDetails(Attributes,
				"partyRows.rows", "comment", NStr("vi = 'Diễn giải';
													|ru = 'Комментарий';
													|en = 'Comment'; fa = 'توضیحات';
													|it = 'Комментарий';
													|pl = 'Komentarz';
													|tr = 'Yorum'"), "String");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "contact", NStr("vi = 'Người liên hệ';
													|ru = 'Контактное лицо';
													|en = 'Contact person'; fa = 'شخص تماس';
													|it = 'Contatto';
													|pl = 'Osoba do kontaktu';
													|tr = 'İrtibat kişisi'"), "DMPartyRowContact");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "description", NStr("vi = 'Tên gọi của bên';
														|ru = 'Наименование стороны';
														|en = 'Party name'; fa = 'Party name';
														|it = 'Denominazione parti';
														|pl = 'Nazwa strony';
														|tr = 'Taraf tanımı'"), "DMPartyName");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "party", NStr("vi = 'Bên';
												|ru = 'Сторона';
												|en = 'Party'; fa = 'طرف';
												|it = 'Сторона';
												|pl = 'Strona';
												|tr = 'Taraf'"), "DMParty", True);
			
			AddTableDetails(Attributes,
				"partyRows.rows", "setBy", NStr("vi = 'Đã cài đặt';
												|ru = 'Установил';
												|en = 'Installed by'; fa = 'Installed by';
												|it = 'Установил';
												|pl = 'Ustawił';
												|tr = 'Ayarladı'"), "DMUser");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "signatureDate", NStr("vi = 'Ngày ký';
														|ru = 'Дата подписи';
														|en = 'Date signed'; fa = 'تاریخ امضا';
														|it = 'Data della firma';
														|pl = 'Data podpisu';
														|tr = 'İmza tarihi'"), "Date");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "signed", NStr("vi = 'Đã ký';
												|ru = 'Подписан';
												|en = 'Signed'; fa = 'امضاشده';
												|it = 'Подписан';
												|pl = 'Signed';
												|tr = 'İmzalandı'"), "Boolean");
			
			AddTableDetails(Attributes,
				"partyRows.rows", "signedBy", NStr("vi = 'Người ký';
													|ru = 'Подписал';
													|en = 'Signed by'; fa = 'امضاشده توسط';
													|it = 'Подписал';
													|pl = 'Signed by';
													|tr = 'İmzaladı'"), "DMPartyRowContact");
			
		EndIf;
		
	// Contractor.
	ElsIf ObjectTypeDM = "DMCorrespondent" Then
		
		AddAttribute(Attributes, "name", NStr("vi = 'Tên gọi';
												|ru = 'Наименование';
												|en = 'Description'; fa = 'شرح';
												|it = 'Наименование';
												|pl = 'Description';
												|tr = 'Tanım'"), "String", True);
		If IntegrationWith1CDocumentManagementCached.UseTermCorrespondents() Then
			AddAttribute(Attributes,
				"legalPrivatePerson",
				NStr("vi = 'Dạng đối tác';
					|ru = 'Вид корреспондента';
					|en = 'Correspondent kind'; fa = 'Correspondent kind';
					|it = 'Tipo di corrispondente';
					|pl = 'Rodzaj korespondenta';
					|tr = 'Muhabir türü'"),
				"DMLegalPrivatePerson",
				True);
		Else
			AddAttribute(Attributes,
				"legalPrivatePerson",
				NStr("vi = 'Dạng đối tác';
					|ru = 'Вид контрагента';
					|en = 'Counterparty type'; fa = 'نوع طرف حساب';
					|it = 'Tipo del contraente';
					|pl = 'Rodzaj kontrahenta';
					|tr = 'Cari hesap türü'"),
				"DMLegalPrivatePerson",
				True);
		EndIf;
		AddAttribute(Attributes, "inn", NStr("vi = 'MST';
											|ru = 'ИНН';
											|en = 'TIN'; fa = 'شناسه مالیاتی';
											|it = 'ИНН';
											|pl = 'NIP';
											|tr = 'VKN'"), "String");
		AddAttribute(Attributes, "kpp", NStr("vi = 'Mã chi nhánh';
											|ru = 'КПП';
											|en = 'KPP'; fa = 'KPP';
											|it = 'КПП';
											|pl = 'KPE (Kod Przyczyny wniesienia do Ewidencji)';
											|tr = 'KPP'"), "String");
		AddAttribute(Attributes, "okpo", NStr("vi = 'Mã doanh nghiệp';
												|ru = 'Код по ОКПО';
												|en = 'OKPO code'; fa = 'کد OKPO';
												|it = 'Codice secondo il classificatore russo di imprese e organizzazioni';
												|pl = 'Kod wg OKVED';
												|tr = 'OKPO kodu'"), "String");
		AddAttribute(Attributes, "comment", NStr("vi = 'Diễn giải';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Comment';
												|tr = 'Yorum'"), "String");
		AddAttribute(Attributes, "fullName", NStr("vi = 'Tên đầy đủ';
													|ru = 'Полное наименование';
													|en = 'Full name'; fa = 'نام کامل';
													|it = 'Nome completo';
													|pl = 'Pełna nazwa';
													|tr = 'Tam tanım'"), "String");
		AddAttribute(Attributes, "privatePerson", NStr("vi = 'Cá nhân';
														|ru = 'Физическое лицо';
														|en = 'Person'; fa = 'شخص';
														|it = 'Persona fisica';
														|pl = 'Osoba fizyczna';
														|tr = 'Gerçek kişi'"), "DMPrivatePerson");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Responsible person'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMUser");
		
	EndIf;
	
	// States.
	If ObjectTypeDM = "DMIncomingDocument"
			Or ObjectTypeDM = "DMOutgoingDocument" Or ObjectTypeDM = "DMInternalDocument" Then
		
		If GetAll Or (TypesSettings.statusEnabled = True And TypesSettings.statusChangeEnabled = True) Then
			AddAttribute(Attributes, "statusApproval", NStr("vi = 'Trạng thái thống nhất';
															|ru = 'Состояние согласования';
															|en = 'Approval state '; fa = 'وضعیت تأیید';
															|it = 'Stato omologazione';
															|pl = 'Status uzgodnienia';
															|tr = 'Onay durumu'"), "DMDocumentStatus");
			AddAttribute(Attributes, "statusConfirmation", NStr("vi = 'Trạng thái phê duyệt';
																|ru = 'Состояние утверждения';
																|en = 'Confirmation state'; fa = 'Confirmation state';
																|it = 'Stato conferma';
																|pl = 'Status zatwierdzenia';
																|tr = 'Onay durumu'"), "DMDocumentStatus");
			AddAttribute(Attributes, "statusConsideration", NStr("vi = 'Trạng thái xem xét';
																|ru = 'Состояние рассмотрения';
																|en = 'Review state'; fa = 'Review state';
																|it = 'Stato valutazione';
																|pl = 'Status rozpatrzenia';
																|tr = 'Değerlendirme durumu'"), "DMDocumentStatus");
			AddAttribute(Attributes, "statusPerformance", NStr("vi = 'Trạng thái thực hiện';
																|ru = 'Состояние исполнения';
																|en = 'Execution state'; fa = 'Execution state';
																|it = 'Stato esecuzione';
																|pl = 'Status wykonania';
																|tr = 'Yürütme durumu'"), "DMDocumentStatus");
			AddAttribute(Attributes, "statusRegistration", NStr("vi = 'Trạng thái đăng ký';
																|ru = 'Состояние регистрации';
																|en = 'Registration state'; fa = 'Registration state';
																|it = 'Stato registrazione';
																|pl = 'Status rejestracji';
																|tr = 'Kayıt durumu'"), "DMDocumentStatus");
		EndIf;
		
		If GetAll Or (IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP")
				And ObjectTypeDM = "DMInternalDocument"
					And TypesSettings.statusEnabled = True And TypesSettings.statusChangeEnabled = True) Then
			AddAttribute(Attributes, "statusSigning", NStr("vi = 'Trạng thái ký';
															|ru = 'Состояние подписания';
															|en = 'Signature state'; fa = 'وضعیت امضا';
															|it = 'Stato firma';
															|pl = 'Status podpisania';
															|tr = 'İmza durumu'"), "DMDocumentStatus");
		EndIf;
		
	EndIf;
	
	// Additional properties.
	For Each AdditionalProperty1 In AddAttributes Do
		
		If Not IntegrationWith1CDocumentManagementCore.PropertySet(AdditionalProperty1, "propertyValueTypes") Then
			Continue;
		EndIf;
		
		Types = New ValueList;
		For Each TypeDetails In AdditionalProperty1.propertyValueTypes Do
			If TypeDetails.xdtoClassName = "integer" Then
				ValueType = "Number";
			ElsIf TypeDetails.xdtoClassName = "boolean" Then
				ValueType = "Boolean";
			ElsIf TypeDetails.xdtoClassName = "string" Then
				ValueType = "String";
			ElsIf TypeDetails.xdtoClassName = "date" Then
				ValueType = "Date";
			Else
				ValueType = TypeDetails.xdtoClassName;
			EndIf;
			Types.Add(ValueType, TypeDetails.presentation);
		EndDo;
		
		AddAdditionalProps(Attributes,
			AdditionalProperty1.name,
			Types,
			AdditionalProperty1.objectID.ID,
			AdditionalProperty1.objectID.type);
		
	EndDo;
	
	Attributes.Sort("Order DESC, TableForSorting, ThisIsTable DESC, Presentation");
	
	Return Attributes;
	
EndFunction

// Returns the correspondence of the XDTO properties and the details of the object form.
//
// Parameters:
//   ObjectType - String - type of the XDTO object.
//
// Returns:
//   Structure - where the key is the name of the XDTO property, and the value is the name of the document form details.
//
Function MatchingXDTPropertiesAndObjectFormDetailsTo(ObjectType) Export
	
	Result = New Structure;
	
	// General details of documents.
	If Find(ObjectType, "Document") <> 0 Then
		
		Result.Insert("title", "Description");
		Result.Insert("summary", "LongDesc");
		Result.Insert("comment", "Comment");
		Result.Insert("regNumber", "RegistrationNumber");
		Result.Insert("regDate", "RegistrationDate");
		Result.Insert("performanceDate", "TaskDueDate");
		Result.Insert("sum", "Sum");
		Result.Insert("currency", "Currency");
		Result.Insert("status", "State");
		Result.Insert("organization", "Organization");
		Result.Insert("subdivision", "Department");
		Result.Insert("activityMatter", "QuestionOfActivity");
		Result.Insert("responsible", "EmployeeResponsible");
		Result.Insert("accessLevel", "AccessBar");
		Result.Insert("documentType", "DocumentKind");
		
		Result.Insert("statusRegistration", "StateRegistration");
		Result.Insert("statusConfirmation", "StateConfirmation");
		If ObjectType = "DMInternalDocument"
				And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
			Result.Insert("statusSigning", "StateSigning");
		EndIf;
		Result.Insert("statusApproval", "StateApproval");
		Result.Insert("statusConsideration", "StateReviewal");
		Result.Insert("statusPerformance", "StatePerformance");
		
		// Templates.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.8.1") Then
			Result.Insert("template", "Template");
		EndIf;
		
		// Projects.
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			Result.Insert("project", "Project");
		EndIf;
		
		// The composition of the document
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
			Result.Insert("numberOfSheets", "SheetQuantity");
			Result.Insert("numberOfAnnexes", "NumberOfApplications");
			Result.Insert("sheetsInAnnexes", "SheetsInApplications");
			Result.Insert("numberOfCopies", "Copies");
		EndIf;
		
		// Document Storage
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
			Result.Insert("caseFilesCatalog", "CaseFileNomenclature");
			Result.Insert("caseFileDossier", "ToDoItem");
		EndIf;
		
	EndIf;
	
	// Incoming document.
	If ObjectType = "DMIncomingDocument" Then
		
		Result.Insert("externalNumber", "SenderSNumber");
		Result.Insert("externalDate", "SenderDate");
		Result.Insert("correspondent", "Sender");
		Result.Insert("signer", "SignedBy");
		Result.Insert("addressee", "Addressee");
		Result.Insert("deliveryMethod", "MethodOfObtaining");
		
	// Outgoing document.
	ElsIf ObjectType = "DMOutgoingDocument" Then
		
		Result.Insert("externalNumber", "RecipientNumber");
		Result.Insert("externalDate", "RecipientDate");
		Result.Insert("sent", "Shipped_5");
		Result.Insert("sendDate", "DateSent");
		
		Result.Insert("correspondent", "Recipient");
		Result.Insert("addressee", "Addressee");
		Result.Insert("signer", "SignedBy");
		Result.Insert("author", "Prepared");
		Result.Insert("deliveryMethod", "SendingMethod");
		
	// Internal document.
	ElsIf ObjectType = "DMInternalDocument" Then
		
		Result.Insert("beginDate", "ValidityStartDate");
		Result.Insert("endDate", "ValidityEndDate");
		Result.Insert("openEnded", "Permanent");
		
		Result.Insert("folder", "Folder");
		Result.Insert("author", "Prepared");
		
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.13.1") Then
			Result.Insert("addressee", "Addressee");
		EndIf;
		
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.0") Then
			Result.Insert("VAT", "VATAmount");
			
			LineProducts_ = New Structure;
			LineProducts_.Insert("product", "Products");
			LineProducts_.Insert("quantity", "Count");
			LineProducts_.Insert("measurementUnit", "UnitOfMeasure");
			LineProducts_.Insert("price", "Price");
			LineProducts_.Insert("VATRate", "VATRate");
			LineProducts_.Insert("VAT", "VATAmount");
			LineProducts_.Insert("total", "Sum");
			
			ProductLines_3 = New Structure;
			ProductLines_3.Insert("rows", New Array);
			ProductLines_3.rows.Add("Goods");
			ProductLines_3.rows.Add(LineProducts_);
			
			Result.Insert("productRows", ProductLines_3);
		EndIf;
		
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP") Then
			SideString = New Structure;
			SideString.Insert("comment", "Comment");
			SideString.Insert("contact", "ContactPerson");
			SideString.Insert("description", "Description");
			SideString.Insert("party", "Party");
			SideString.Insert("setBy", "Set");
			SideString.Insert("signatureDate", "SignatureDate");
			SideString.Insert("signed", "Signed");
			SideString.Insert("signedBy", "SignedBy");
			
			SideStrings = New Structure;
			SideStrings.Insert("rows", New Array);
			SideStrings.rows.Add("Parties");
			SideStrings.rows.Add(SideString);
			
			Result.Insert("partyRows", SideStrings);
			
			ContractorsLine = New Structure;
			ContractorsLine.Insert("contact", "ContactPerson");
			ContractorsLine.Insert("correspondent", "Counterparty");
			ContractorsLine.Insert("signedFromTheCorrespondent", "SignedFromCounterparty");
			
			CounterpartiesLines = New Structure;
			CounterpartiesLines.Insert("rows", New Array);
			CounterpartiesLines.rows.Add("Counterparties");
			CounterpartiesLines.rows.Add(ContractorsLine);
			
			Result.Insert("correspondentRows", CounterpartiesLines);
		EndIf;
		
		Result.Insert("signer", "SignedBy");
		Result.Insert("correspondent", "Counterparty");
		Result.Insert("contactPerson", "ContactPerson");
		Result.Insert("prolongationProcedure", "ExtensionProcedure");
		
		CFItemsRow = New Structure;
		CFItemsRow.Insert("item", "CFItem");
		CFItemsRow.Insert("total", "Sum");
		CFItemsRow.Insert("VAT", "VATAmount");
		
		CFItemsRows = New Structure;
		CFItemsRows.Insert("rows", New Array);
		CFItemsRows.rows.Add("CFItems");
		CFItemsRows.rows.Add(CFItemsRow);
		
		Result.Insert("cashFlowRows", CFItemsRows);
		
	// Counterparty (correspondent).
	ElsIf ObjectType = "DMCorrespondent" Then
		
		Result.Insert("name", "Description");
		Result.Insert("inn", "TIN");
		Result.Insert("kpp", "CRTR");
		Result.Insert("okpo", "NCBOCode");
		Result.Insert("fullName", "FullDescr");
		Result.Insert("comment", "Comment");
		Result.Insert("legalPrivatePerson", "LegalEntityIndividual");
		Result.Insert("privatePerson", "Person");
		Result.Insert("responsible", "EmployeeResponsible");
		
	EndIf;
	
	// Marking the deletion.
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1") Then
		Result.Insert("deletionMark", "DeletionMark");
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the correspondence of the XDTO properties to the details of the document form responsible for the states.
//
// Parameters:
//   DocumentType - String - type of the XDTO object.
//
// Returns:
//   Structure:
//     * statusRegistration - String - "State registration"
//     * statusConsideration - String - "State Review"
//     * statusApproval - String - "State of agreement"
//     * statusConfirmation - String - "State of affirmation"
//     * statusSigning - String - "State signing"
//     * statusPerformance - String - "State of fulfillment"
//
Function MatchingXDTPropertiesToDocumentStates(DocumentType) Export
	
	MatchingBankDetails = New Structure;
	
	MatchingBankDetails.Insert("statusRegistration",	"StateRegistration");
	MatchingBankDetails.Insert("statusConsideration",	"StateReviewal");
	MatchingBankDetails.Insert("statusApproval",		"StateApproval");
	MatchingBankDetails.Insert("statusConfirmation",	"StateConfirmation");
	If DocumentType = "DMInternalDocument"
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		MatchingBankDetails.Insert("statusSigning",	"StateSigning");
	EndIf;
	MatchingBankDetails.Insert("statusPerformance",	"StatePerformance");
	
	Return MatchingBankDetails;
	
EndFunction

#EndRegion

#Region Private

// Returns the Enumeration value.Options for the right to fill in the requirements.Expression in a built-in language.
//
Function VariantExpression()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The specified value.
//
Function OptionValue_()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The object's props.
//
Function OptionProps()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The object's props.
//
Function TablePropsOption()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.TableAttribute;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.From the template.
//
Function OptionTemplate()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.FromTemplate;
	
EndFunction

// Adds additional details to the row of the table with filling in the columns specified as parameters.
//
Procedure AddAdditionalProps(Attributes, Presentation, Type, AdditionalAttribute5ID, AdditionalAttribute5Type)
	
	NewRow = Attributes.Add();
	NewRow.Presentation = Presentation;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.AdditionalAttribute5 = True;
	NewRow.AdditionalAttribute5ID = AdditionalAttribute5ID;
	NewRow.AdditionalAttribute5Type = AdditionalAttribute5Type;
	
EndProcedure

// Adds the props to the row of the table with filling in the columns specified as parameters.
//
Procedure AddAttribute(Attributes, Name, Presentation, Type, Mandatory = False)
	
	NewRow = Attributes.Add();
	NewRow.Name = Name;
	NewRow.Presentation = Presentation;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.Mandatory = Mandatory;
	
	If Lower(Name) = "documenttype" Then
		NewRow.Order = 1;
	EndIf;
	
EndProcedure

// Adds the props to the subordinate row of the table, with filling in the columns specified as parameters.
//
Procedure AddTableDetails(Attributes, TableName, Name, Presentation, Type, Mandatory = False)
	
	NewRow = Attributes.Add();
	NewRow.Table = TableName;
	NewRow.TableForSorting = TableName;
	NewRow.Name = Name;
	NewRow.Presentation = Presentation;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.Mandatory = Mandatory;
	
EndProcedure

// Adds the template's details to the table row.
//
Procedure AddTemplateDetails_(Proxy, Attributes, NameOfDocumentProperty, XDTOTemplate,
	Val TemplatePropertyName = Undefined)
	
	If TemplatePropertyName = Undefined Then // By default, they match.
		TemplatePropertyName = NameOfDocumentProperty;
	EndIf;
	
	If Not XDTOTemplate.IsSet(TemplatePropertyName) Then
		Return;
	EndIf;
	
	NewRow = Attributes.Add();
	NewRow.AttributeNameObjectDM = NameOfDocumentProperty;
	NewRow.IsAdditionalAttributeDM = False;
	If IntegrationWith1CDocumentManagementCore.ThisIsObjectProperty(Proxy, XDTOTemplate, TemplatePropertyName) Then
		NewRow.TemplateMeaning = XDTOTemplate[TemplatePropertyName].name;
		NewRow.TemplateID = XDTOTemplate[TemplatePropertyName].objectID.ID;
		NewRow.TemplateType = XDTOTemplate[TemplatePropertyName].objectID.type;
	Else // Primitive type.
		NewRow.TemplateMeaning = XDTOTemplate[TemplatePropertyName];
	EndIf;
	
EndProcedure

// Adds a table to a table row with the columns specified as parameters filled in.
//
Procedure AddTable(Attributes, Name, Presentation)
	
	NewRow = Attributes.Add();
	NewRow.ThisIsTable = True;
	NewRow.Name = Name;
	NewRow.TableForSorting = Name;
	NewRow.Presentation = Presentation;
	
EndProcedure

// Fills in the details of the payment request.
//
// Parameters:
//   AttributesStructure1 - Structure:
//     * Parties - ValueTable:
//         ** Description - String
//
Procedure FillInPaymentRequestDetails(AttributesStructure1)
	
	AttributesStructure1.Counterparty = "";
	AttributesStructure1.CounterpartyID = "";
	AttributesStructure1.CounterpartyType = "";
	AttributesStructure1.Counterparties.Clear();
	If (AttributesStructure1.RecipientType = "DMCorrespondent"
		Or AttributesStructure1.RecipientType = IntegrationWith1CDocumentManagementCoreServerCall.TypeNameIS(
			"DMCorrespondent"))
				And ValueIsFilled(AttributesStructure1.RecipientID) Then
		CounterpartyLine = AttributesStructure1.Counterparties.Add();
		CounterpartyLine.Counterparty = AttributesStructure1.Recipient;
		CounterpartyLine.CounterpartyID = AttributesStructure1.RecipientID;
		CounterpartyLine.CounterpartyType = AttributesStructure1.RecipientType;
		AttributesStructure1.Counterparty = AttributesStructure1.Recipient;
		AttributesStructure1.CounterpartyID = AttributesStructure1.RecipientID;
		AttributesStructure1.CounterpartyType = AttributesStructure1.RecipientType;
	EndIf;
	
	AttributesStructure1.Parties.Clear();
	If ValueIsFilled(AttributesStructure1.OrganizationID) Then
		PayerParty = AttributesStructure1.Parties.Add();
		PayerParty.Party = AttributesStructure1.Organization;
		PayerParty.PartyID = AttributesStructure1.OrganizationID;
		PayerParty.PartyType = AttributesStructure1.OrganizationType;
		NamePayerXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
			"DMPartyName", "Плательщик"); //@NON-NLS-2
		PayerParty.Description = NamePayerXDTO.name;
		PayerParty.DescriptionID = NamePayerXDTO.objectID.ID;
		PayerParty.DescriptionType = NamePayerXDTO.objectID.type;
	EndIf;
	If ValueIsFilled(AttributesStructure1.RecipientID) Then
		RecipientParty = AttributesStructure1.Parties.Add();
		RecipientParty.Party = AttributesStructure1.Recipient;
		RecipientParty.PartyID = AttributesStructure1.RecipientID;
		RecipientParty.PartyType = AttributesStructure1.RecipientType;
		NameRecipientXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
			"DMPartyName", "Получатель"); //@NON-NLS-2
		RecipientParty.Description = NameRecipientXDTO.name;
		RecipientParty.DescriptionID = NameRecipientXDTO.objectID.ID;
		RecipientParty.DescriptionType = NameRecipientXDTO.objectID.type;
	EndIf;
	
EndProcedure

// In the case when an expression in the built-in language returns the name or synonym
// of the enumeration value, the procedure fills in the object's props with the corresponding value.
// If the type of the props is not an enumeration, the props will be filled in with the transmitted result.
//
// Parameters:
//   Object - Arbitrary - an arbitrary object whose details need to be filled in.
//   AttributeName - String - the details that need to be filled in.
//   Result - Arbitrary - the result of executing an expression in the embedded language.
//
Procedure FillInResultOfExpressionInBuiltInLanguage(Object, AttributeName, Result)
	
	If TypeOf(Result) = Type("String") And Result <> "" And IsEnum(Object[AttributeName]) Then
		EnumValueName = TrimAll(Result);
		EnumManager = Common.ObjectManagerByRef(Object[AttributeName]);
		AttributeMetadata = Object[AttributeName].Metadata();
		If AttributeMetadata.EnumValues.Find(EnumValueName) = Undefined Then
			// Fill in the enumeration by the transferred synonym
			Object[AttributeName] = EnumManager.EmptyRef();
			For Each EnumerationValue In AttributeMetadata.EnumValues Do
				If Upper(TrimAll(EnumerationValue.Synonym)) = Upper(EnumValueName) Then
					Object[AttributeName] = EnumManager[EnumerationValue.Name];
					Break;
				EndIf;
			EndDo;
		Else
			// Fill in the enumeration by the passed name
			Object[AttributeName] = EnumManager[EnumValueName];
		EndIf;
	Else
		Object[AttributeName] = Result;
	EndIf;
	
EndProcedure

Function ConvertValueToPrimitiveType(TypeName, Value)
	
	If TypeName = "String" And TypeOf(Value) <> Type("String") Then
		Return String(Value);
		
	ElsIf TypeName = "Number" And (TypeOf(Value) = Type("String") Or TypeOf(Value) = Type("Boolean")) Then
		Return Number(Value);
		
	ElsIf (TypeName = "Date" Or TypeName = "DateTime") And TypeOf(Value) = Type("String") Then
		Return Date(Value);
		
	ElsIf TypeName = "Boolean" And (TypeOf(Value) = Type("Number") Or TypeOf(Value) = Type("String")) Then
		Return Boolean(Value);
		
	EndIf;
	
	Return Value;
	
EndFunction

Procedure CheckTheAttributeFillingRulesDM(IntegrationRule, ObjectIS, ObjectMetadataIS, ObjectAttributesIS,
		AllMapItemDetailsUpTo, ErrorList)
	
	For Each Rule In IntegrationRule.AttributeFillingRulesDM Do
		
		CheckParameters = New Structure;
		CheckParameters.Insert("CurrentValue");
		CheckParameters.Insert("AttributeRepresentationBefore");
		CheckParameters.Insert("ErrorText");
		
		AttributeBefore = AllMapItemDetailsUpTo.Find(Rule.AttributeNameObjectDM, "Name");
		TableBefore = AllMapItemDetailsUpTo.Find(Rule.Table, "Name");
		AttributeTypePresentationDM = "";
		
		If Rule.ThisIsTable Then
			AttributeTypePresentationDM = NStr("vi = 'bảng DM';
												|ru = 'таблицы ДО';
												|en = 'EDI tables'; fa = 'EDI tables';
												|it = 'таблицы ДО';
												|pl = 'tabele DM';
												|tr = 'DM tabloları'");
			
		ElsIf Rule.IsAdditionalAttributeDM Then
			AttributeTypePresentationDM = NStr("vi = 'mục tin bổ sung DM';
												|ru = 'доп. реквизита ДО';
												|en = 'Additional EDI attribute'; fa = 'Additional EDI attribute';
												|it = 'доп. реквизита ДО';
												|pl = 'dod. atrybutu DM';
												|tr = 'sDM ek öznitelikleri'");
			
		ElsIf Not ValueIsFilled(Rule.Table) Then
			AttributeTypePresentationDM = NStr("vi = 'mục tin DM';
												|ru = 'реквизита ДО';
												|en = 'EDI attribute'; fa = 'EDI attribute';
												|it = 'реквизита ДО';
												|pl = 'atrybutu DM';
												|tr = 'DM öznitelikleri'");
			
		EndIf;
		
		If ValueIsFilled(Rule.Table) Then
			CheckParameters.AttributeRepresentationBefore = StrTemplate(NStr("vi = 'mục tin ""%1"" của bảng DM ""%2""';
																			|ru = 'реквизита ""%1"" таблицы ДО ""%2""';
																			|en = '""%1"" attribute of the ""%2"" EDI table'; fa = '""%1"" attribute of the ""%2"" EDI table';
																			|it = 'реквизита ""%1"" таблицы ДО ""%2""';
																			|pl = 'atrybutu ""%1"" tabeli DM ""%2""';
																			|tr = '""%1"" özniteliğinin  ""%2"" DM tabloları'"),
				?(AttributeBefore = Undefined, Rule.AttributeNameObjectDM, AttributeBefore.Presentation),
				?(TableBefore = Undefined, Rule.Table, TableBefore.Presentation));
			
		Else
			CheckParameters.AttributeRepresentationBefore = StrTemplate("%1 ""%2""",
				AttributeTypePresentationDM,
				?(AttributeBefore = Undefined, Rule.AttributeNameObjectDM, AttributeBefore.Presentation));
			
		EndIf;
		
		Try
			
			If Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
				
				If ValueIsFilled(Rule.Table) Then // This is the props of the tabular part.
					
					SplitRow = StrSplit(Rule.AttributeNameObjectIS, ".");
					If SplitRow.Count() = 1 Then
						CurrentMetadata = ObjectMetadataIS; // MetadataObjectDocument
						AttributeName = SplitRow[0];
						
					ElsIf SplitRow.Count() = 2 Then
						CheckParameters.ErrorText = StrTemplate(
							NStr("vi = 'Đã chọn phương án điền từ mục tin ""%1"" của bảng không tồn tại ""%2""';
								|ru = 'Выбран вариант заполнения из реквизита ""%1"" несуществующей таблицы ""%2""';
								|en = 'Filling option is selected from the ""%1"" attribute of the non-existing table ""%2""'; fa = 'Filling option is selected from the ""%1"" attribute of the non-existing table ""%2""';
								|it = 'Выбран вариант заполнения из реквизита ""%1"" несуществующей таблицы ""%2""';
								|pl = 'Wybrano wariant wypełnienia z atrybutu ""%1"" nieistniejącej tabeli ""%2""';
								|tr = 'Mevcut olmayan tablonun ""%1"" özniteliğinden seçilen doldurma seçeneği ""%2""'"),
								SplitRow[1],
								SplitRow[0]);
						CurrentMetadata = ObjectMetadataIS.TabularSections[SplitRow[0]]; // MetadataObjectDocument
						AttributeName = SplitRow[1];
						
					Else
						CheckParameters.ErrorText = NStr("vi = 'Cơ chế điền mục tin của bảng
							|không hỗ trợ tương tác với mục tin của hệ thống tương tác thông qua điểm';
							|ru = 'Механизм заполнения реквизитов таблиц
							|не поддерживает обращение к реквизиту ИС через точку';
							|en = 'Table attribute filling mechanism
							|does not support access to IS attribute using dot syntax'; fa = 'Table attribute filling mechanism
							|does not support access to IS attribute using dot syntax';
							|it = 'Механизм заполнения реквизитов таблиц
							|не поддерживает обращение к реквизиту ИС через точку';
							|pl = 'Mechanizm wypełnienia atrybutów tabel
							|nie obsługuje zwrócenia się do atrybutu Systemu Zintegrowanego przez kropkę';
							|tr = 'Tablo özniteliklerini doldurma mekanizması
							|entegre sistemi özniteliklerine nokta aracılığıyla erişmeyi desteklemiyor'");
						Raise CheckParameters.ErrorText;
						
					EndIf;
					
					If Rule.IsAdditionalAttributeIS Then
						CheckParameters.ErrorText = NStr("vi = 'Cơ chế điền mục tin của bảng
							|không hỗ trợ điền từ mục tin bổ sung';
							|ru = 'Механизм заполнения реквизитов таблиц
							|не поддерживает заполнение из доп. реквизитов';
							|en = 'Table attribute filling mechanism
							|does not support filling from additional attributes'; fa = 'Table attribute filling mechanism
							|does not support filling from additional attributes';
							|it = 'Механизм заполнения реквизитов таблиц
							|не поддерживает заполнение из доп. реквизитов';
							|pl = 'Mechanizm wypełnienia atrybutów tabel
							|nie obsługuje wypełnienia z dodatkowych atrybutów';
							|tr = 'Tablo özniteliklerini doldurma mekanizması
							|ek özniteliklerden doldurmayı desteklemiyor'");
						
					Else
						CheckParameters.ErrorText = StrTemplate(
							NStr("vi = 'Đã chọn phương án điền từ mục tin không tồn tại ""%1""';
								|ru = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
								|en = 'Filling option from the ""%1"" non-existing attribute is selected'; fa = 'Filling option from the ""%1"" non-existing attribute is selected';
								|it = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
								|pl = 'Wybrano wariant wypełnienia z nieistniejącego atrybutu ""%1""';
								|tr = 'Var olmayan ""%1"" özniteliğinden doldurma seçeneği seçildi'"), AttributeName);
						
					EndIf;
					
					If Not IsStandardAttribute(CurrentMetadata, AttributeName) Then
						CheckParameters.CurrentValue = CurrentMetadata.Attributes[AttributeName];
					EndIf;
					
				Else // Regular or additional Attributes.
					
					If Rule.AttributeNameObjectIS = "Presentation" Then
						
						CheckParameters.CurrentValue = String(ObjectIS);
						
					ElsIf Rule.IsAdditionalAttributeIS Then
						
						If ObjectAttributesIS.Find(
								Rule.AdditionalAttributeIS, "AdditionalAttributeIS") = Undefined Then
							CheckParameters.ErrorText = StrTemplate(
								NStr("vi = 'Đã chọn phương án điền từ mục tin bổ sung không tồn tại ""%1""';
									|ru = 'Выбран вариант заполнения из несуществующего доп. реквизита ""%1""';
									|en = 'Filling option is selected from non-existing additional attribute ""%1""'; fa = 'Filling option is selected from non-existing additional attribute ""%1""';
									|it = 'Выбран вариант заполнения из несуществующего доп. реквизита ""%1""';
									|pl = 'Wybrano wariant wypełnienia z nieistniejącego dodatkowego atrybutu ""%1""';
									|tr = 'Mevcut olmayan bir öznitelikten doldurma seçeneği seçildi ""%1""'"),
									Common.ObjectAttributeValue(
										Rule.AdditionalAttributeIS, "Description"));
							Raise CheckParameters.ErrorText;
						EndIf;
						
					ElsIf StrFind(Rule.AttributeNameObjectIS, ".") > 0 Then
						
						ExpressionParameters = New Structure("CheckParameters, ObjectIS",
							CheckParameters,
							ObjectIS);
						
						SplitRow = StrSplit(Rule.AttributeNameObjectIS, ".");
						Expression = New Array;
						Expression.Add("Parameters.CheckParameters.CurrentValue = Parameters.ObjectIS");
						For Each Item In SplitRow Do
							Expression.Add(StrTemplate("[""%1""]", Item));
						EndDo;
						Expression.Add(";");
						
						CheckParameters.ErrorText = StrTemplate(
							NStr("vi = 'Đã chọn phương án điền từ mục tin không tồn tại ""%1""';
								|ru = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
								|en = 'Filling option from the ""%1"" non-existing attribute is selected'; fa = 'Filling option from the ""%1"" non-existing attribute is selected';
								|it = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
								|pl = 'Wybrano wariant wypełnienia z nieistniejącego atrybutu ""%1""';
								|tr = 'Var olmayan ""%1"" özniteliğinden doldurma seçeneği seçildi'"),
								Rule.AttributeNameObjectIS);
						
						Common.ExecuteInSafeMode(StrConcat(Expression), ExpressionParameters);
						
					Else // The usual Attribute of the object.
						
						If Rule.ThisIsTable Then
							CheckParameters.ErrorText = StrTemplate(
								NStr("vi = 'Đã chọn phương án điền từ bảng không tồn tại ""%1""';
									|ru = 'Выбран вариант заполнения из несуществующей таблицы ""%1""';
									|en = 'Filling option is selected from non-existing table ""%1""'; fa = 'Filling option is selected from non-existing table ""%1""';
									|it = 'Выбран вариант заполнения из несуществующей таблицы ""%1""';
									|pl = 'Wybrano wariant wypełnienia z nieistniejącej tabeli ""%1""';
									|tr = 'Var olmayan ""%1"" tablosundan doldurma seçeneği seçildi'"),
									Rule.AttributeNameObjectIS);
						Else
							CheckParameters.ErrorText = StrTemplate(
								NStr("vi = 'Đã chọn phương án điền từ mục tin không tồn tại ""%1""';
									|ru = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
									|en = 'Filling option from the ""%1"" non-existing attribute is selected'; fa = 'Filling option from the ""%1"" non-existing attribute is selected';
									|it = 'Выбран вариант заполнения из несуществующего реквизита ""%1""';
									|pl = 'Wybrano wariant wypełnienia z nieistniejącego atrybutu ""%1""';
									|tr = 'Var olmayan ""%1"" özniteliğinden doldurma seçeneği seçildi'"),
									Rule.AttributeNameObjectIS);
						EndIf;
						
						CheckParameters.CurrentValue = ObjectIS[Rule.AttributeNameObjectIS];
						
					EndIf;
					
				EndIf;
				
			ElsIf Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
				
				Try
					CheckUploadRuleExpression(Rule.ComputedExpression, ObjectIS);
				Except
					ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
					CheckParameters.ErrorText = StrTemplate(
						NStr("vi = 'Không thể thực hiện biểu thức bằng ngôn ngữ hệ thống do nguyên nhân:
							|""%1""';
							|ru = 'Не удалось выполнить выражение на встроенном языке по причине:
							|""%1""';
							|en = 'Cannot execute the expression in 1C:Enterprise language due to:
							|""%1""'; fa = 'Cannot execute the expression in 1C:Enterprise language due to:
							|""%1""';
							|it = 'Не удалось выполнить выражение на встроенном языке по причине:
							|""%1""';
							|pl = 'Nie udało się wypełnić wyrażenia w języku wbudowanym z powodu:
							|""%1""';
							|tr = 'Gömülü dilde ifade şu nedenle gerçekleştirilemedi: 
							|""%1""'"), ExceptionText);
					Raise;
				EndTry;
				
			EndIf;
			
		Except
			ErrorList.Add(
				StrTemplate(
					NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Chuyển sang 1C:Document Management""):
						|%2';
						|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Передача в 1С:Документооборот""):
						|%2';
						|en = 'Filling rule error %1 (Tab ""Transfer to 1C:Document Management""):
						|%2'; fa = 'Filling rule error %1 (Tab ""Transfer to 1C:Document Management""):
						|%2';
						|it = 'Ошибка в правиле заполнения %1 (Закладка ""Передача в 1С:Документооборот""):
						|%2';
						|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Przekazanie do 1С:Document Management""):
						|%2';
						|tr = 'Doldurma kuralında hata %1 (Sekme ""1C:Document Management''e transfer""):
						|%2'"),
							CheckParameters.AttributeRepresentationBefore,
							CheckParameters.ErrorText));
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure CheckTheAttributeFillingRulesIS(IntegrationRule, ObjectIS, XDTODataObject, ObjectAttributesIS,
		AttributesOfTheCurrentDocumentKindDM, AllMapItemDetailsUpTo, ErrorList)
	
	For Each Rule In IntegrationRule.AttributeFillingRulesIS Do
		
		AttributeIS = ObjectAttributesIS.Find(Rule.AttributeNameObjectIS, "Name");
		TableIS = ObjectAttributesIS.Find(Rule.Table, "Name");
		AttributePresentationIS = "";
		AttributeTypePresentationIS = "";
		
		If Rule.ThisIsTable Then
			AttributeTypePresentationIS = NStr("vi = 'bảng của hệ thống được tích hợp';
												|ru = 'таблицы ИС';
												|en = 'IS tables'; fa = 'IS tables';
												|it = 'таблицы ИС';
												|pl = 'tabele Systemu Zintegrowanego';
												|tr = 'Entegre Sistemi tabloları'");
			
		ElsIf Rule.IsAdditionalAttributeIS Then
			AttributeTypePresentationIS = NStr("vi = 'mục tin bổ sung của hệ thống được tích hợp';
												|ru = 'доп. реквизита ИС';
												|en = 'Additional IS attribute '; fa = 'Additional IS attribute ';
												|it = 'доп. реквизита ИС';
												|pl = 'dod. atrybutu Systemu Zintegrowanego';
												|tr = 'Entegre Sistemi ek öznitelikleri'");
			
		ElsIf Not ValueIsFilled(Rule.Table) Then
			AttributeTypePresentationIS = NStr("vi = 'mục tin của hệ thống được tích hợp';
												|ru = 'реквизита ИС';
												|en = 'IS attribute'; fa = 'IS attribute';
												|it = 'реквизита ИС';
												|pl = 'atrybutu Systemu Zintegrowanego';
												|tr = 'Entegre Sistemi özniteliği'");
			
		EndIf;
		
		If ValueIsFilled(Rule.Table) Then
			AttributePresentationIS = StrTemplate(NStr("vi = 'mục tin ""%1"" của bảng của hệ thống được tích hợp ""%2""';
														|ru = 'реквизита ""%1"" таблицы ИС ""%2""';
														|en = 'attribute ""%1"" of the ""%2"" IS table'; fa = 'attribute ""%1"" of the ""%2"" IS table';
														|it = 'реквизита ""%1"" таблицы ИС ""%2""';
														|pl = 'atrybutu ""%1"" tabeli Systemu Zintegrowanego ""%2""';
														|tr = '""%1"" özniteliği ""%2"" Entegre Sistemi tabloları'"),
				?(AttributeIS = Undefined, Rule.AttributeNameObjectIS, AttributeIS.Presentation),
				?(TableIS = Undefined, Rule.Table, TableIS.Presentation));
			
		Else
			AttributePresentationIS = StrTemplate("%1 ""%2""",
				AttributeTypePresentationIS,
				?(AttributeIS = Undefined, Rule.AttributeNameObjectIS, AttributeIS.Presentation));
			
		EndIf;
		
		If Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
			
			If Not Rule.IsAdditionalAttributeDM Then
				
				SplitRow = StrSplit(Rule.AttributeNameObjectDM, ".", False);
				If SplitRow.Count() = 1 Then // "property"
					Table = "";
					AttributeName = Rule.AttributeNameObjectDM;
					
				ElsIf SplitRow.Count() = 2 Then // "the list.property"
					Table = "";
					AttributeName = StrTemplate("%1.%2", SplitRow[0], SplitRow[1]);
					
				ElsIf SplitRow.Count() = 3 Then // "the list.list.property"
					Table = StrTemplate("%1.%2", SplitRow[0], SplitRow[1]);
					AttributeName = SplitRow[2];
					
				Else
					ErrorList.Add(
						StrTemplate(
							NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
								|Đã chỉ định tên mục tin nguồn dữ liệu điền không hợp lệ: %2';
								|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
								|Указано недопустимое имя реквизита-источника данных заполнения: %2';
								|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
								|Invalid filling data attribute name is specified: %2'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
								|Invalid filling data attribute name is specified: %2';
								|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
								|Указано недопустимое имя реквизита-источника данных заполнения: %2';
								|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
								|Podano niedopuszczaną nazwę atrybutu-źródła danych wypełnienia: %2';
								|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
								|Doldurma veri kaynağı özniteliğinin geçersiz adı belirtildi: %2'"),
									AttributePresentationIS,
									Rule.AttributeNameObjectDM));
					Continue;
					
				EndIf;
				
				Filter = New Structure("Name, Table", AttributeName, Table);
				
				FoundRows = AttributesOfTheCurrentDocumentKindDM.FindRows(Filter);
				
				If FoundRows.Count() = 0 Then
					AllDetailsDMProps = AllMapItemDetailsUpTo.FindRows(Filter);
					AllDetailsDMPayment = AllMapItemDetailsUpTo.FindRows(New Structure("Name", Table));
					
					If Rule.ThisIsTable Then
						ErrorList.Add(
							StrTemplate(
								NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
									|đã chọn phương án điền từ bảng không tồn tại ""%2""';
									|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
									|выбран вариант заполнения из несуществующей таблицы ""%2""';
									|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
									|filling option is selected from non-existing table ""%2""'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
									|filling option is selected from non-existing table ""%2""';
									|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
									|выбран вариант заполнения из несуществующей таблицы ""%2""';
									|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
									|wybrano wariant wypełnienia z nieistniejącej tabeli ""%2""';
									|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
									|var olmayan tablodan doldurma seçeneği seçildi ""%2""'"),
										AttributePresentationIS,
										?(AllDetailsDMProps.Count() = 0,
											Rule.AttributeNameObjectDM,
											AllDetailsDMProps[0].Presentation)));
					Else
						If ValueIsFilled(Table) Then
							ErrorList.Add(
								StrTemplate(
									NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
										|đã chọn phương án điền từ mục tin ""%2"" của bảng không tồn tại ""%3""';
										|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
										|выбран вариант заполнения из реквизита ""%2"" несуществующей таблицы ""%3""';
										|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""';
										|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
										|выбран вариант заполнения из реквизита ""%2"" несуществующей таблицы ""%3""';
										|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
										|wybrano wariant wypełnienia z atrybutu ""%2"" nieistniejącej tabeli ""%3""';
										|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
										|öznitelikten doldurma seçeneği seçildi""%2"" var olmayan tablonun""%3""'"),
											AttributePresentationIS,
											?(AllDetailsDMProps.Count() = 0,
												Rule.AttributeNameObjectDM,
												AllDetailsDMProps[0].Presentation),
											?(AllDetailsDMPayment.Count() = 0,
												Table,
												AllDetailsDMPayment[0].Presentation)));
						Else
							ErrorList.Add(
								StrTemplate(
									NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
										|đã chọn phương án điền từ mục tin không tồn tại ""%2""';
										|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
										|выбран вариант заполнения из несуществующего реквизита ""%2""';
										|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
										|filling option is selected from non-existing attribute ""%2""'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
										|filling option is selected from non-existing attribute ""%2""';
										|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
										|выбран вариант заполнения из несуществующего реквизита ""%2""';
										|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
										|wybrano wariant wypełnienia z nieistniejącego atrybutu ""%2""';
										|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
										|var olmayan öznitelikten seçenek seçildi ""%2""'"),
											AttributePresentationIS,
											?(AllDetailsDMProps.Count() = 0,
												Rule.AttributeNameObjectDM,
												AllDetailsDMProps[0].Presentation)));
						EndIf;
					EndIf;
				EndIf;
				
			Else // Additional Attributes TO.
				
				Filter = New Structure("AdditionalAttribute5ID, AdditionalAttribute5Type",
					Rule.AdditionalAttributeDMID,
					Rule.AdditionalAttributeDMType);
				FoundRows = AttributesOfTheCurrentDocumentKindDM.FindRows(Filter);
				
				If FoundRows.Count() = 0 Then
					ErrorList.Add(
						StrTemplate(
							NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
								|đã chọn phương án điền từ mục tin bổ sung không tồn tại ""%2""';
								|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
								|выбран вариант заполнения из несуществующего доп. реквизита ""%2""';
								|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
								|filling option is selected from non-existing additional attribute ""%2""'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
								|filling option is selected from non-existing additional attribute ""%2""';
								|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
								|выбран вариант заполнения из несуществующего доп. реквизита ""%2""';
								|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
								|wybrano wariant wypełnienia z nieistniejącego dodatkowego atrybutu ""%2""';
								|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
								|var olmayan ek öznitelikten seçenek seçildi ""%2""'"),
									AttributePresentationIS,
									Rule.AdditionalAttributeDMID));
				EndIf;
				
			EndIf;
			
		ElsIf Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
			
			Try
				CheckLoadingRuleExpression(Rule.ComputedExpression, XDTODataObject, ObjectIS);
			Except
				ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(
					StrTemplate(
						NStr("vi = 'Lỗi trong quy tắc điền %1 (Thẻ ""Nhận từ 1C:Document Management""):
							|Không thể thực hiện biểu thức bằng ngôn ngữ hệ thống do nguyên nhân:
							|""%2""';
							|ru = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
							|Не удалось выполнить выражение на встроенном языке по причине:
							|""%2""';
							|en = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
							|Cannot execute the expression in 1C:Enterprise language due to:
							|""%2""'; fa = 'Filling rule error %1 (Tab ""Receive from 1C:Document Management""):
							|Cannot execute the expression in 1C:Enterprise language due to:
							|""%2""';
							|it = 'Ошибка в правиле заполнения %1 (Закладка ""Получение из 1С:Документооборота""):
							|Не удалось выполнить выражение на встроенном языке по причине:
							|""%2""';
							|pl = 'Błąd w regule wypełnienia %1 (Zakładka ""Odbiór z 1С:Document Management""):
							|Nie udało się wykonać wyrażenia w języku wbudowanym z powodu:
							|""%2""';
							|tr = '%1 doldurma kuralında hata (Sekme ""1C:Document Management''ten alma""):
							|Gömülü dilde ifade şu nedenle yürütülemedi:
							| ""%2""'"),
								AttributePresentationIS,
								ExceptionText));
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ApplicationPartyForXDTOPayment(XDTODataObject, PredefinedPartyName)
	
	Result = Undefined;
	
	InstalledTSSide = IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "partyRows");
	
	If InstalledTSSide Then
		For Each XDTOSide In XDTODataObject.partyRows.rows Do
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOSide, "description")
					And IntegrationWith1CDocumentManagementCore.PropertySet(XDTOSide.description, "predefinedName")
					And XDTOSide.description.predefinedName = PredefinedPartyName Then
				Result = XDTOSide.party;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns True if the passed value is an enumeration.
//
Function IsEnum(Value)
	
	If Value = Undefined Then
		Return False;
	EndIf;
	
	Return Enums.AllRefsType().ContainsType(TypeOf(Value));
	
EndFunction

// Returns True if the name describes one of the primitive types, and False otherwise.
//
Function IsPrimitiveType(TypeName)
	
	Return TypeName = "String"
		Or TypeName = "Date"
		Or TypeName = "Number"
		Or TypeName = "DateTime"
		Or TypeName = "Boolean";
	
EndFunction

Function IsStandardAttribute(CurrentMetadata, AttributeName)
	
	For Each Attribute In CurrentMetadata.StandardAttributes Do
		If Attribute.Name = AttributeName Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#EndIf