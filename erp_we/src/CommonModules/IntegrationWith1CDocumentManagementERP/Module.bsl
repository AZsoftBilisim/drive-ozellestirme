#Region Public

// Returns the default partner access group.
//
// Returns:
//   CatalogRef.PartnerAccessGroups - the default access group.
//   Undefined - if partner access groups are not used.
//
Function PartnerAccessGroupByDefault() Export
	
	If Not Catalogs.PartnerAccessGroups.AccessGroupsAreUsed() Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	YouMustCreateElement = False;
	
	DefaultElementName = NStr("vi = 'Nhóm truy cập mặc định';
								|ru = 'Группа доступа по умолчанию';
								|en = 'Default access group'; fa = 'Default access group';
								|it = 'Gruppo di accesso da impostazione predefinita';
								|pl = 'Grupa dostępu domyślna';
								|tr = 'Varsayılan erişim grubu'");
	
	Query = New Query(
		"SELECT TOP 2
		|	PartnerAccessGroups.Ref AS Ref,
		|	CASE
		|		WHEN PartnerAccessGroups.Description = &DefaultElementName
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsDefaultItemForSharing
		|FROM
		|	Catalog.PartnerAccessGroups AS PartnerAccessGroups
		|WHERE
		|	NOT PartnerAccessGroups.DeletionMark
		|
		|ORDER BY
		|	ThisIsDefaultItemForSharing DESC");
	Query.SetParameter("DefaultElementName", DefaultElementName);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If Selection.Count() = 1 Or Selection.ThisIsDefaultItemForSharing Then
			DefaultAccessGroup = Selection.Ref;
		Else
			YouMustCreateElement = True;
		EndIf;
	Else
		YouMustCreateElement = True;
	EndIf;
	
	If YouMustCreateElement Then
		AccessGroupObject = Catalogs.PartnerAccessGroups.CreateItem();
		AccessGroupObject.Description = DefaultElementName;
		
		AccessGroupObject.DataExchange.Load = True;
		
		Try
			AccessGroupObject.Write();
			DefaultAccessGroup = AccessGroupObject.Ref;
		Except
			DefaultAccessGroup = Catalogs.PartnerAccessGroups.EmptyRef();
			IntegrationWith1CDocumentManagementCore.WriteError(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return DefaultAccessGroup;
	
EndFunction

// See IntegrationWith1CDocumentManagementCoreOverridable.FillInDetailsFromConsumer.
//
Procedure FillInDetailsFromConsumer(Proxy, XDTODataObject, ReferenceToConsumer) Export
	
	If ReferenceToConsumer.IsEmpty() Then
		Return;
	EndIf;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	If TypeOf(XDTODataObject) = Type("String") Or XDTODataObject = Undefined Then
		FillInXDTOEnumerationFromConsumer(XDTODataObject, ReferenceToConsumer, Settings);
		
	ElsIf TypeOf(XDTODataObject) = Type("XDTODataObject") Then
		FillInReferenceObjectXDTOFromConsumer(Proxy, XDTODataObject, ReferenceToConsumer, Settings);
		
	EndIf;
	
EndProcedure

// Creates a rule for integration with 1C:Document management.
//
// Parameters:
//   ObjectTypeIS - String - the type of IP object.
//   ObjectTypeDM - String - the type of document flow object.
//   DocumentKind - XDTODataObject - type of document flow document.
//   Folder - XDTODataObject - Workflow document folder.
//
// Returns:
//   Structure:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule.
//     * ObjectTypeIS - String - the type of IP object.
//     * ObjectTypeDM - String - the object type is UP TO.
//     * ObjectPresentationIS - String - representation of the IP object.
//     * ObjectPresentationDM - String - representation of the object BEFORE.
//     * IDOfDocumentType - String - id of the document type BEFORE.
//     * TypeOfDocumentType - String - the type of document type BEFORE.
//
Function CreateIntegrationRule(ObjectTypeIS, ObjectTypeDM, DocumentKind, Folder) Export
	
	Rule = Catalogs.RulesForIntegrationWith1CDocumentManagement.CreateItem();
	Rule.Fill(Undefined);
	Rule.ObjectTypeIS = ObjectTypeIS;
	Rule.ObjectTypeDM = ObjectTypeDM;
	Rule.Comment = NStr("vi = 'Đã tạo tự động';
						|ru = 'Создано автоматически';
						|en = 'Created automatically'; fa = 'Created automatically';
						|it = 'Creato automaticamente';
						|pl = 'Utworzono automatycznie';
						|tr = 'Otomatik olarak oluşturuldu'");
	
	RulesForIntegrationManager = Catalogs.RulesForIntegrationWith1CDocumentManagement;
	ExpressionTemplates =
		IntegrationWith1CDocumentManagementCoreServerCall.ExpressionTemplatesInEmbeddedLanguage();
	
	// type of document.
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(DocumentKind);
	FillingRule.ShouldUpdateBefore = False;
	FillingRule.KeyAttribute_ = True;
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"documentType",
		FillingRule);
	
	// Folder.
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(Folder);
	FillingRule.ShouldUpdateBefore = False;
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"folder",
		FillingRule);
	
	FillCommonAttributes(RulesForIntegrationManager, ObjectTypeIS, Rule);
	FillInPrivateDetails(RulesForIntegrationManager, ObjectTypeIS, Rule, ExpressionTemplates);
	
	Rule.Write();
	
	IDOfDocumentType = DocumentKind.objectID.ID; // String
	TypeOfDocumentType = DocumentKind.objectID.type; // String
	
	Result = New Structure;
	Result.Insert("Ref", Rule.Ref);
	Result.Insert("ObjectTypeIS", ObjectTypeIS);
	Result.Insert("ObjectTypeDM", ObjectTypeDM);
	Result.Insert("ObjectPresentationIS", ObjectTypeIS);
	Result.Insert("ObjectPresentationDM", ObjectTypeDM);
	Result.Insert("IDOfDocumentType", IDOfDocumentType);
	Result.Insert("TypeOfDocumentType", TypeOfDocumentType);
	
	Return Result;
	
EndFunction

// Returns the value of the Attribute describing the approval State of the ERP object corresponding
// to the transmitted value of the approval State in 1C:Document flow.
//
// Parameters:
//   AttributeType - Boolean
//                - EnumRef - the type of ERP item Attribute.
//   AttributeName - String - Attribute name of the ERP object.
//   ObjectType - CatalogObject
//              - DocumentObject - type of ERP item.
//   StateOfApprovalBefore - EnumRef.ApprovalStatesIn1CDocumentManagement - the status of the agreement in UP to.
//
// Returns:
//   Boolean
//   EnumRef
//
Function StateOfERPApproval(AttributeType, AttributeName, ObjectType, StateOfApprovalBefore) Export
	
	Result = Undefined;
	
	// The installation of the props is "Agreed" according to the state of approval BEFORE.
	If AttributeType = Type("Boolean") And AttributeName = "Approved" Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = True;
		Else
			Result = False;
		EndIf;
		
	// Selection of enumeration values-approval statuses according to the approval status BEFORE.
	ElsIf AttributeType = Type("EnumRef.StatusesOfCommercialProposalsForCustomers") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfCommercialProposalsForCustomers.Valid;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfCommercialProposalsForCustomers.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfCommercialProposalsForCustomers.NotApproved;
		Else
			Result = Enums.StatusesOfCommercialProposalsForCustomers.Draft;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.CounterpartyContractStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.CounterpartyContractStatuses.Valid;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.CounterpartyContractStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.CounterpartyContractStatuses.NotApproved;
		Else
			Result = Enums.CounterpartyContractStatuses.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.StatusesOfTermsOfSales") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfTermsOfSales.Valid;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfTermsOfSales.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfTermsOfSales.NotApproved;
		Else
			Result = Enums.StatusesOfTermsOfSales.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.StatusesOfTermsOfPurchase") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfTermsOfPurchase.Valid;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfTermsOfPurchase.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfTermsOfPurchase.NotApproved;
		Else
			Result = Enums.StatusesOfTermsOfPurchase.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.SalesOrderStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.SalesOrderStatuses.ToSupply;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.SalesOrderStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.SalesOrderStatuses.NotApproved;
		Else
			Result = Enums.SalesOrderStatuses.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.PurchaseOrderStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.PurchaseOrderStatuses.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.PurchaseOrderStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.PurchaseOrderStatuses.NotApproved;
		Else
			Result = Enums.PurchaseOrderStatuses.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.StatusesOfDiscrepancyReport") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfDiscrepancyReport.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfDiscrepancyReport.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfDiscrepancyReport.NotApproved;
		Else
			Result = Enums.StatusesOfDiscrepancyReport.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.StatusesOfRequestsForReturnOfGoodsFromCustomers") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
		Else
			Result = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.StatusesOfPaymentRequests") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfPaymentRequests.AgreedUpon;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfPaymentRequests.IsRejected;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfPaymentRequests.NotAgreedUpon;
		Else
			Result = Enums.StatusesOfPaymentRequests.NotAgreedUpon;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.CashTransferOrderStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.CashTransferOrderStatuses.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.CashTransferOrderStatuses.TurnDown;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.CashTransferOrderStatuses.NotApproved;
		Else
			Result = Enums.CashTransferOrderStatuses.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.ProductPricingStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.ProductPricingStatuses.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.ProductPricingStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.ProductPricingStatuses.NotApproved;
		Else
			Result = Enums.ProductPricingStatuses.NotApproved;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.RebatesKindsStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.RebatesKindsStatuses.Valid;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.RebatesKindsStatuses.Closed;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.RebatesKindsStatuses.Prepared;
		Else
			Result = Enums.RebatesKindsStatuses.Prepared;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.RebatesDocumentStatuses") Then
		
		If ObjectType = Type("DocumentObject.DebitCustomerRebates")
				And Not GetFunctionalOption("UseApprovalOfCustomerRebatesWriteOffs") Then
			Result = Enums.RebatesDocumentStatuses.Approved;
		ElsIf ObjectType = Type("DocumentObject.WriteOffVendorRebates")
				And Not GetFunctionalOption("UseApprovalOfVendorRebateWriteOffs") Then	
			Result = Enums.RebatesDocumentStatuses.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.RebatesDocumentStatuses.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.RebatesDocumentStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.RebatesDocumentStatuses.AwaitingApproval;
		Else
			Result = Enums.RebatesDocumentStatuses.Draft;
		EndIf;
	ElsIf AttributeType = Type("EnumRef.StatusesOfMaterialProviderOrders") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfMaterialProviderOrders.Approved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfMaterialProviderOrders.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfMaterialProviderOrders.NotApproved;
		Else
			Result = Enums.StatusesOfMaterialProviderOrders.NotApproved;
		EndIf;
	ElsIf AttributeType = Type("EnumRef.TollingOrderStatuses") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.TollingOrderStatuses.ForFulfillment;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.TollingOrderStatuses.NotApproved;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.TollingOrderStatuses.NotApproved;
		Else
			Result = Enums.TollingOrderStatuses.NotApproved;
		EndIf;
	ElsIf AttributeType = Type("EnumRef.StatusesOfEngineeringChangeOrders") Then
		If StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.Approved Then
			Result = Enums.StatusesOfEngineeringChangeOrders.Confirmed;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved Then
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		ElsIf StateOfApprovalBefore = Enums.ApprovalStatesIn1CDocumentManagement.AwaitingApproval Then
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		Else
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the value of the Attribute describing the approval State of the UP object corresponding
// to the passed value of the approval State in 1C:Document flow.
//
// Parameters:
//   AttributeType - Boolean
//                - EnumRef - the type of ERP item Attribute.
//   AttributeName - String - Attribute name of the ERP object.
//   ObjectType - CatalogObject
//              - DocumentObject - type of ERP item.
//   ApprovalStateDM - String - The State of approval in the DO.
//
// Returns:
//   Boolean
//   EnumRef
//
Function StateOfApprovalOfERP(AttributeType, AttributeName, ObjectType, ApprovalStateDM) Export
	
	Result = Undefined;
	
	// Selection of enumeration values-approval statuses according to the approval status BEFORE.
	
	If AttributeType = Type("EnumRef.PlanStatuses") Then
		If ApprovalStateDM = "Confirmed" Then
			Result = Enums.PlanStatuses.Upholded;
		ElsIf ApprovalStateDM = "NotConfirmed" Then
			Result = Enums.PlanStatuses.RolledBack_;
		ElsIf ApprovalStateDM = "AwaitingConfirmation" Then
			Result = Enums.PlanStatuses.AwaitingConfirmation;
		Else
			Result = Enums.PlanStatuses.UnderPreparation;
		EndIf;
		
	ElsIf AttributeType = Type("EnumRef.ExpenseReportStatuses") Then
		If ApprovalStateDM = "Confirmed" Then
			Result = Enums.ExpenseReportStatuses.Upholded;
		ElsIf ApprovalStateDM = "NotConfirmed" Then
			Result = Enums.ExpenseReportStatuses.Prepared;
		ElsIf ApprovalStateDM = "AwaitingConfirmation" Then
			Result = Enums.ExpenseReportStatuses.Prepared;
		Else
			Result = Enums.ExpenseReportStatuses.Prepared;
		EndIf;
	ElsIf AttributeType = Type("EnumRef.StatusesOfEngineeringChangeOrders") Then
		If ApprovalStateDM = "Confirmed" Then
			Result = Enums.StatusesOfEngineeringChangeOrders.Confirmed;
		ElsIf ApprovalStateDM = "NotConfirmed" Then
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		ElsIf ApprovalStateDM = "AwaitingConfirmation" Then
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		Else
			Result = Enums.StatusesOfEngineeringChangeOrders.CreatedOn;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Searches for the appropriate legal entity enumeration value from the legalPrivatePerson Attribute of the XDTO object of type DMCorrespondent or
// DMOrganization.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the original object whose match was not found in the current IB.
//
// Returns:
//   EnumRef.LegalEntityIndividual
//
Function LegalEntityNaturalPersonFromXDTOObject(XDTODataObject) Export
	
	LegalEntityIndividual = Enums.LegalEntityIndividual.Entity;
	
	If XDTODataObject = Undefined
			Or Not IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "legalPrivatePerson") Then
		Return LegalEntityIndividual;
	EndIf;
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		
		If XDTODataObject.legalPrivatePerson.objectID.ID = "ИндивидуальныйПредприниматель" Then //@NON-NLS-1
			LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur;
			
		ElsIf XDTODataObject.legalPrivatePerson.objectID.ID = "ЮрЛицоНеРезидент" Then //@NON-NLS-1
			LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident;
			
		ElsIf XDTODataObject.legalPrivatePerson.objectID.ID = "ФизЛицо" Then //@NON-NLS-1
			LegalEntityIndividual = Enums.LegalEntityIndividual.Person;
			
		EndIf;
		
	ElsIf Settings.UseIntegrationBefore3 Then
		
		If XDTODataObject.legalPrivatePerson = "Individ" Then
			LegalEntityIndividual = Enums.LegalEntityIndividual.Person;
			
		ElsIf XDTODataObject.legalPrivatePerson = "LglPersonNonResident" Then
			LegalEntityIndividual = Enums.LegalEntityIndividual.LegalEntityNonResident;
			
		ElsIf XDTODataObject.legalPrivatePerson = "IndividualEntrepreneur" Then
			LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur;
			
		EndIf;
		
	EndIf;
	
	Return LegalEntityIndividual;
	
EndFunction

#EndRegion

#Region Private

Procedure FillCommonAttributes(RulesForIntegrationManager, ObjectTypeIS, Rule)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	AccessBar = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMAccessLevel");
	AccessBar.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy);
	AccessBar.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
	AccessBar.name = NStr("vi = 'Chung';
							|ru = 'Общий';
							|en = 'Shared'; fa = 'اشتراکی';
							|it = 'Generale';
							|pl = 'Wspólny';
							|tr = 'Ortak'");
	
	QuestionOfActivity = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMActivityMatter");
	QuestionOfActivity.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(Proxy);
	QuestionOfActivity.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
	QuestionOfActivity.name = NStr("vi = 'Hoạt động chính';
									|ru = 'Основная деятельность';
									|en = 'Core activity'; fa = 'فعالیت اصلی';
									|it = 'Attività principale';
									|pl = 'Podstawowa działalność';
									|tr = 'Ana faaliyet'");
	
	Document = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMInternalDocument");
	Document.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		"",
		"DMInternalDocument");
	Document.name = NStr("vi = 'Tạm thời';
						|ru = 'Временный';
						|en = 'Temporary'; fa = 'موقت';
						|it = 'Temporaneo';
						|pl = 'Temporary';
						|tr = 'Geçici'");
	Document.accessLevel = AccessBar;
	Document.activityMatter = QuestionOfActivity;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
	Query.object = Document;
	
	IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	
	AllowedWithoutReposting = Undefined;
	AllowedWithReposting = Undefined;
	TypeParts = StrSplit(ObjectTypeIS, ".", False);
	If Lower(TypeParts[0]) = "document" Then
		AllowedWithoutReposting =
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
		AllowedWithReposting =
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	EndIf;
	
	Rule.DoNotCreateRelationsByLinks = True;
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	// Title
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"title",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Presentation"));
	
	// access bar
	
	// We will get the access stamp
	AccessBar = IntegrationWith1CDocumentManagementCoreServerCall.FindVDOObjectByName(
		"DMAccessLevel",
		NStr("vi = 'Chung';
			|ru = 'Общий';
			|en = 'Shared'; fa = 'اشتراکی';
			|it = 'Generale';
			|pl = 'Wspólny';
			|tr = 'Ortak'"));
	// Let's set a rule
	If AccessBar <> Undefined Then
		FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(AccessBar);
		FillingRule.ShouldUpdateBefore = False;
		RulesForIntegrationManager.AddAttributeFillingRuleDM(
			Rule,
			Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
			"accessLevel",
			FillingRule);
	EndIf;
	
	// question of activity
	
	// We will get a question of activity
	QuestionOfActivity = IntegrationWith1CDocumentManagementCoreServerCall.FindVDOObjectByName(
		"DMActivityMatter",
		NStr("vi = 'Hoạt động chính';
			|ru = 'Основная деятельность';
			|en = 'Core activity'; fa = 'فعالیت اصلی';
			|it = 'Attività principale';
			|pl = 'Podstawowa działalność';
			|tr = 'Ana faaliyet'"));
	// Let's set a rule
	If QuestionOfActivity <> Undefined Then
		FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(QuestionOfActivity);
		FillingRule.ShouldUpdateBefore = False;
		RulesForIntegrationManager.AddAttributeFillingRuleDM(
			Rule,
			Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
			"activityMatter",
			FillingRule);
	EndIf;
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval");
	FillingRule.ChangeMode = AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Status",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	FillingRule.ChangeMode = AllowedWithReposting;
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Organization",
		"organization",
		FillingRule);
	
	If (ObjectTypeIS <> "Document.PaymentRequest")
			Or (Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP")) Then
		RulesForIntegrationManager.AddPairRule(
			Rule,
			"Counterparty",
			"correspondent",
			FillingRule);
	EndIf;
	
	FillingRule.ChangeMode = AllowedWithoutReposting;
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Comment",
		"comment",
		FillingRule);
	
EndProcedure

// Used only for integration with UP to 3. Fills in the enumeration value from the XDTO of the DM package.
//
// Parameters:
//   XDTODataObject - String - enumeration value.
//   ReferenceToConsumer - AnyRef - a reference to the original consumer configuration object.
//   Settings - See IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration
//
Procedure FillInXDTOEnumerationFromConsumer(XDTODataObject, ReferenceToConsumer, Settings)
	
	If Settings.UseIntegrationBefore3 = False Then
		Return;
	EndIf;
	
	If TypeOf(ReferenceToConsumer) = Type("EnumRef.CompanyIndividual") Then
		
		If ReferenceToConsumer = Enums.CompanyIndividual.BusinessEntity Then
			XDTODataObject = "LglPerson";
			
		ElsIf ReferenceToConsumer = Enums.CompanyIndividual.Individual Then
			XDTODataObject = "Individ";
			
		EndIf;
		
	ElsIf TypeOf(ReferenceToConsumer) = Type("EnumRef.LegalEntityIndividual") Then
		
		If ReferenceToConsumer = Enums.LegalEntityIndividual.Entity Then
			XDTODataObject = "LglPerson";
			
		ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.Person Then
			XDTODataObject = "Individ";
			
		ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.LegalEntityNonResident Then
			XDTODataObject = "LglPersonNonResident";
			
		ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
			XDTODataObject = "IndividualEntrepreneur";
			
		EndIf;

	ElsIf TypeOf(ReferenceToConsumer) = Type("EnumRef.IndividualCompany") Then
		
		If ReferenceToConsumer = Enums.IndividualCompany.Company Then
			XDTODataObject = "LglPerson";
			
		ElsIf ReferenceToConsumer = Enums.IndividualCompany.Person_ Then
			XDTODataObject = "Individ";
			
		EndIf;
		
		
	ElsIf TypeOf(ReferenceToConsumer) = Type("CatalogRef.VATRates") Then
		
		If ReferenceToConsumer = Catalogs.VATRates.EXCLUDINGVAT Then
			XDTODataObject = "WithoutVAT";
			
		Else
			Rate1 = Common.ObjectAttributeValue(ReferenceToConsumer, "Rate1");
			If Rate1 = 0 Then
				XDTODataObject = "VAT0";
				
			ElsIf Rate1 = 10 Then
				XDTODataObject = "VAT10";
				
			ElsIf Rate1 = 18 Then
				XDTODataObject = "VAT18";
				
			ElsIf Rate1 = 20 Then
				XDTODataObject = "VAT20";
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInReferenceObjectXDTOFromConsumer(Proxy, XDTODataObject, ReferenceToConsumer, Settings)
	
	SetPrivilegedMode(True);
	
	If TypeOf(ReferenceToConsumer) = Type("EnumRef.CompanyIndividual") Then
		
		If Settings.UseIntegrationBefore2 Then
			XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMLegalPrivatePerson",
				ReferenceToConsumer,
				False);
			XDTODataObject.objectID.type = "DMLegalPrivatePerson";
			If ReferenceToConsumer = Enums.CompanyIndividual.BusinessEntity Then
				XDTODataObject.objectID.ID = "ЮрЛицо"; //@NON-NLS-1
			ElsIf ReferenceToConsumer = Enums.CompanyIndividual.Individual Then
				XDTODataObject.objectID.ID = "ФизЛицо"; //@NON-NLS-1
			EndIf;
		ElsIf Settings.UseIntegrationBefore3 Then
			FillInXDTOEnumerationFromConsumer(XDTODataObject, ReferenceToConsumer, Settings);
		EndIf;
		
	ElsIf TypeOf(ReferenceToConsumer) = Type("EnumRef.LegalEntityIndividual") Then
		
		If Settings.UseIntegrationBefore2 Then
			XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMLegalPrivatePerson",
				ReferenceToConsumer,
				False);
			XDTODataObject.objectID.type = "DMLegalPrivatePerson";
			If ReferenceToConsumer = Enums.LegalEntityIndividual.Entity Then
				XDTODataObject.objectID.ID = "ЮрЛицо"; //@NON-NLS-1
			ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.Person Then
				XDTODataObject.objectID.ID = "ФизЛицо"; //@NON-NLS-1
			ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
				XDTODataObject.objectID.ID = "ИндивидуальныйПредприниматель"; //@NON-NLS-1
			ElsIf ReferenceToConsumer = Enums.LegalEntityIndividual.LegalEntityNonResident Then
				XDTODataObject.objectID.ID = "ЮрЛицоНеРезидент"; //@NON-NLS-1
			EndIf;
		ElsIf Settings.UseIntegrationBefore3 Then
			FillInXDTOEnumerationFromConsumer(XDTODataObject, ReferenceToConsumer, Settings);
		EndIf;
		
	ElsIf TypeOf(ReferenceToConsumer) = Type("EnumRef.IndividualCompany") Then
		
		If Settings.UseIntegrationBefore2 Then
			XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMLegalPrivatePerson",
				ReferenceToConsumer,
				False);
			XDTODataObject.objectID.type = "DMLegalPrivatePerson";
			If ReferenceToConsumer = Enums.IndividualCompany.Company Then
				XDTODataObject.objectID.ID = "ЮрЛицо"; //@NON-NLS-1
			ElsIf ReferenceToConsumer = Enums.IndividualCompany.Person_ Then
				XDTODataObject.objectID.ID = "ФизЛицо"; //@NON-NLS-1
			EndIf;
		ElsIf Settings.UseIntegrationBefore3 Then
			FillInXDTOEnumerationFromConsumer(XDTODataObject, ReferenceToConsumer, Settings);
		EndIf;
		
		
	ElsIf TypeOf(ReferenceToConsumer) = Type("CatalogRef.VATRates") Then
		
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMVATRateUniversal") Then
			Attributes = Common.ObjectAttributesValues(ReferenceToConsumer,
				"BeginOfPeriod, EndOfPeriod, Rate1, CalculatedRate, Country");
			If ValueIsFilled(Attributes.BeginOfPeriod) Then
				XDTODataObject.beginOfPeriod = Attributes.BeginOfPeriod;
			EndIf;
			If ValueIsFilled(Attributes.EndOfPeriod) Then
				XDTODataObject.endOfPeriod = Attributes.EndOfPeriod;
			EndIf;
			If ValueIsFilled(Attributes.Rate1) Then
				XDTODataObject.rate = Attributes.Rate1;
			EndIf;
			If ValueIsFilled(Attributes.CalculatedRate) Then
				XDTODataObject.calculatedRate = Attributes.CalculatedRate;
			EndIf;
			If ValueIsFilled(Attributes.Country) Then
				XDTODataObject.country = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMCountry",
					Attributes.Country);
			EndIf;
			ValueOfVATRateEnumeration = "";
			FillInXDTOEnumerationFromConsumer(ValueOfVATRateEnumeration, ReferenceToConsumer, Settings);
			If ValueIsFilled(ValueOfVATRateEnumeration) Then
				XDTODataObject.predefinedName = ValueOfVATRateEnumeration;
			EndIf;
		Else
		EndIf;
		
	ElsIf (IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMCorrespondent")
				And TypeOf(ReferenceToConsumer) = Type("CatalogRef.Counterparties"))
			Or (IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMOrganization")
				And TypeOf(ReferenceToConsumer) = Type("CatalogRef.Companies")) Then
		
		Attributes = Common.ObjectAttributesValues(ReferenceToConsumer,
			"TIN, CRTR, LegalEntityIndividual, NCBOCode, DescriptionFull");
		
		If ValueIsFilled(Attributes.TIN) Then
			XDTODataObject.inn = Attributes.TIN;
		EndIf;
		If ValueIsFilled(Attributes.CRTR) Then
			XDTODataObject.kpp = Attributes.CRTR;
		EndIf;
		If ValueIsFilled(Attributes.NCBOCode) Then
			XDTODataObject.okpo = Attributes.NCBOCode;
		EndIf;
		If ValueIsFilled(Attributes.DescriptionFull) Then
			XDTODataObject.fullName = Attributes.DescriptionFull;
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.FillInDetailsFromConsumer(
			Proxy,
			XDTODataObject.legalPrivatePerson,
			Attributes.LegalEntityIndividual);
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMContactPerson")
			And TypeOf(ReferenceToConsumer) = Type("CatalogRef.ContactPersonsForPartners") Then
		
		Query = New Query(
			"SELECT
			|	ContactPersonsForPartners.JobTitleOnBusinessCard AS JobTitle,
			|	ContactPersonsForPartners.Comment AS Comment,
			|	ContactPersonsForPartners.Owner AS Partner
			|INTO ContactPersonDetails
			|FROM
			|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|WHERE
			|	ContactPersonsForPartners.Ref = &Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ContactPersonDetails.JobTitle AS JobTitle,
			|	ContactPersonDetails.Comment AS Comment,
			|	ISNULL(Counterparties.Ref, UNDEFINED) AS Counterparty
			|FROM
			|	ContactPersonDetails AS ContactPersonDetails
			|		LEFT JOIN Catalog.Counterparties AS Counterparties
			|		ON ContactPersonDetails.Partner = Counterparties.Partner
			|WHERE
			|	NOT Counterparties.DeletionMark");
		Query.SetParameter("Ref", ReferenceToConsumer);
		Selection = Query.Execute().Select();
		CounterpartiesCount = Selection.Count();
		
		If Selection.Next() Then
			XDTODataObject.position = Selection.JobTitle;
			XDTODataObject.comment = Selection.Comment;
			If CounterpartiesCount = 1 And ValueIsFilled(Selection.Counterparty) Then
				XDTODataObject.correspondent = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMCorrespondent",
					Selection.Counterparty);
			EndIf;
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMPrivatePerson")
			And TypeOf(ReferenceToConsumer) = Type("CatalogRef.Persons")
			And Not Common.ObjectAttributeValue(ReferenceToConsumer, "IsFolder") Then
		
		ListOfAttributes = New Array;
		ListOfAttributes.Add("BirthDate");
		ListOfAttributes.Add("TIN");
		ListOfAttributes.Add("LASTFIRSTNAME");
		ListOfAttributes.Add("InsuranceNumberOfTheFIU");
		Attributes = Common.ObjectAttributesValues(ReferenceToConsumer, StrConcat(ListOfAttributes, ","));
		
		If ValueIsFilled(Attributes.BirthDate) Then
			XDTODataObject.birthDay = Attributes.BirthDate;
		EndIf;
		If ValueIsFilled(Attributes.TIN)
				And IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "inn") Then
			XDTODataObject.inn = Attributes.TIN;
		EndIf;
		If ValueIsFilled(Attributes.LastFirstName) Then
			XDTODataObject.name = Attributes.LastFirstName;
		EndIf;
		If ValueIsFilled(Attributes.InsuranceNumberOfTheFIU)
				And IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "retirementInsuranceNumber") Then
			XDTODataObject.retirementInsuranceNumber = Attributes.InsuranceNumberOfTheFIU;
		EndIf;
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMBankAccount")
			And (TypeOf(ReferenceToConsumer) = Type("CatalogRef.CounterpartyBankAccounts")
				Or TypeOf(ReferenceToConsumer) = Type("CatalogRef.CompaniesBankAccounts")) Then
		
		Attributes = Common.ObjectAttributesValues(ReferenceToConsumer, "Owner, Bank, AccountNumber");
		
		XDTODataObject.number = Attributes.AccountNumber;
		
		If ValueIsFilled(Attributes.Owner) Then
			If TypeOf(Attributes.Owner) = Type("CatalogRef.Counterparties") Then
				TypeNameXDTO = "DMCorrespondent";
			ElsIf TypeOf(Attributes.Owner) = Type("CatalogRef.Persons") Then
				TypeNameXDTO = "DMPrivatePerson";
			ElsIf TypeOf(Attributes.Owner) = Type("CatalogRef.Companies") Then
				TypeNameXDTO = "DMOrganization";
			EndIf;
			XDTODataObject.owner = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				TypeNameXDTO,
				Attributes.Owner);
		EndIf;
		
		If ValueIsFilled(Attributes.Bank) Then
			XDTODataObject.bank = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMBank",
				Attributes.Bank);
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMSubdivision") Then
		
		Director = Undefined;
		
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.BusinessStructure") Then
			Director = Common.ObjectAttributeValue(ReferenceToConsumer, "BusinessUnitManager");
		EndIf;
		
		If ValueIsFilled(Director) Then
			
			If Settings.UseIntegrationBefore2 Then
				TypeNameXDTO = "DMUser";
			ElsIf Settings.UseIntegrationBefore3 Then
				TypeNameXDTO = "DMEmployee";
			Else
				Return;
			EndIf;
			
			XDTODataObject.head = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				TypeNameXDTO,
				Director,
				False);
			
			XDTODataObject.head.subdivision = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMSubdivision",
				ReferenceToConsumer,
				False);
			
			If TypeOf(Director) = Type("CatalogRef.Persons") Then
				XDTODataObject.head.privatePerson = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMPrivatePerson",
					Director,
					False);
			EndIf;
			
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMUser") Then
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.Users") Then
			Department = Common.ObjectAttributeValue(ReferenceToConsumer, "Department");
			If ValueIsFilled(Department) Then
				XDTODataObject.subdivision = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMSubdivision",
					Department);
			EndIf;
		EndIf;
		
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.Persons") Then
			Query = New Query(
				"SELECT DISTINCT
				|	Users.Ref AS Ref
				|FROM
				|	Catalog.Users AS Users
				|WHERE
				|	Users.Individual = &Individual
				|	AND NOT Users.DeletionMark");
			Query.SetParameter("Individual", ReferenceToConsumer);
			
			SampleUsers = Query.Execute().Select();
			
			If SampleUsers.Count() = 1 Then
				SampleUsers.Next();
				IntegrationWith1CDocumentManagementCore.FillInDetailsFromConsumer(
					Proxy,
					XDTODataObject,
					SampleUsers.Ref);
				
			Else
				XDTODataObject.privatePerson = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMPrivatePerson",
					ReferenceToConsumer);
				
			EndIf;
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMEmployee") Then
		
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.Users") Then
			RequestUser = New Query(
				"SELECT
				|	Users.Individual.Description AS IndividualName,
				|	Users.Department AS Department
				|FROM
				|	Catalog.Users AS Users
				|WHERE
				|	Users.Ref = &User");
			RequestUser.Text = StrReplace(
				RequestUser.Text,
				"Users.Individual.Description",
				"Users.Individual.LASTFIRSTNAME");
			RequestUser.SetParameter("User", ReferenceToConsumer);
			
			SampleUser = RequestUser.Execute().Select();
			If SampleUser.Next() Then
				
				If ValueIsFilled(SampleUser.IndividualName) Then
					XDTODataObject.name = SampleUser.IndividualName;
				EndIf;
				
				If ValueIsFilled(SampleUser.Department) Then
					XDTODataObject.subdivision = IntegrationWith1CDocumentManagementCore.CreateObject(
						Proxy,
						"DMSubdivision",
						SampleUser.Department);
				EndIf;
				
			EndIf;
			
			
		EndIf;
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.Persons") Then
			RequestUser = New Query(
				"SELECT DISTINCT
				|	Users.Ref AS Ref
				|FROM
				|	Catalog.Users AS Users
				|WHERE
				|	Users.Individual = &Individual
				|	AND NOT Users.DeletionMark");
			RequestUser.SetParameter("Individual", ReferenceToConsumer);
			
			SampleUsers = RequestUser.Execute().Select();
			
			If SampleUsers.Count() = 1 Then
				SampleUsers.Next();
				IntegrationWith1CDocumentManagementCore.FillInDetailsFromConsumer(
					Proxy,
					XDTODataObject,
					SampleUsers.Ref);
				
			Else
				XDTODataObject.privatePerson = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMPrivatePerson",
					ReferenceToConsumer);
				
			EndIf;
			
			
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMParty") Then
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.Counterparties") Then
			XDTODataObject.correspondent = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMCorrespondent",
				ReferenceToConsumer);
			
		ElsIf TypeOf(ReferenceToConsumer) = Type("CatalogRef.Companies") Then
			XDTODataObject.organization = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMOrganization",
				ReferenceToConsumer);
			
		ElsIf TypeOf(ReferenceToConsumer) = Type("CatalogRef.Users")
				Or TypeOf(ReferenceToConsumer) = Type("CatalogRef.Persons") Then
			If Settings.UseIntegrationBefore2 Then
				XDTODataObject.user = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMUser",
					ReferenceToConsumer);
			ElsIf Settings.UseIntegrationBefore3 Then
				XDTODataObject.employee = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMEmployee",
					ReferenceToConsumer);
			EndIf;
			
			
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMPartyRowContact") Then
		
		If TypeOf(ReferenceToConsumer) = Type("CatalogRef.ContactPersonsForPartners") Then
			XDTODataObject.contactPerson = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMContactPerson",
				ReferenceToConsumer);
			
		ElsIf TypeOf(ReferenceToConsumer) = Type("CatalogRef.Users")
				Or TypeOf(ReferenceToConsumer) = Type("CatalogRef.Persons") Then
			If Settings.UseIntegrationBefore2 Then
				XDTODataObject.user = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMUser",
					ReferenceToConsumer);
			ElsIf Settings.UseIntegrationBefore3 Then
				XDTODataObject.employee = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMEmployee",
					ReferenceToConsumer);
			EndIf;
			
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure FillInPrivateDetails(RulesForIntegrationManager, ObjectTypeIS, Rule, ExpressionTemplates)
	
	If ObjectTypeIS = "Catalog.TermsOfSale" Then
		SupplementCustomerAgreementIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Catalog.CounterpartyContracts" Then
		AddRuleForIntegratingCounterpartyContracts(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Document.CommercialProposalForCustomer" Then
		SupplementRuleForIntegratingCommercialOfferToClient(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Document.SalesOrder" Then
		AddCustomerOrderIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Document.PurchaseOrder" Then
		AddOrderToSupplierIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Document.RequestForReturnOfGoodsFromCustomer" Then
		AddIntegrationRuleRequestForReturnOfGoodsFromClient(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	ElsIf ObjectTypeIS = "Document.PaymentRequest" Then
		SupplementRuleOfIntegrationApplicationForSpendingMoney(RulesForIntegrationManager, Rule, ExpressionTemplates);
		
	EndIf;
	
EndProcedure

Procedure SupplementCustomerAgreementIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"openEnded",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInIndefiniteVDO"]));
	
	// Side Table
	If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP") Then
		RulesForIntegrationManager.AddAttributeFillingRuleDM(
			Rule,
			Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
			"partyRows.rows",
			RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInPartiesFromAgreement"]));
	EndIf;
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Description",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("title"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Number",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("regNumber"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Date",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("regDate"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Approved",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval"));
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"DocumentAmount",
		"sum",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ValidityStartDate",
		"beginDate",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ValidityEndDate",
		"endDate",
		FillingRule);
	
EndProcedure

Procedure AddRuleForIntegratingCounterpartyContracts(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInLBOfSvTO"]));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"openEnded",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInIndefiniteVDO"]));
	
	// Side Table
	If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP") Then
		RulesForIntegrationManager.AddAttributeFillingRuleDM(
			Rule,
			Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
			"partyRows.rows",
			RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInPartiesFromContract"]));
	EndIf;
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Description",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("title"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Number",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("regNumber"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Date",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("regDate"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Approved",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval"));
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Sum",
		"sum",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ARAPCurrency",
		"currency",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Department",
		"subdivision",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ValidityStartDate",
		"beginDate",
		FillingRule);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ValidityEndDate",
		"endDate",
		FillingRule);
	
EndProcedure

Procedure SupplementRuleForIntegratingCommercialOfferToClient(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"sum",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInAmountFromOrder"]));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInVATFromOrder"]));
	
	// Side Table
	If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP") Then
		RulesForIntegrationManager.AddAttributeFillingRuleDM(
			Rule,
			Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
			"partyRows.rows",
			RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInPartiesFromAgreement"]));
	EndIf;
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("sum");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"DocumentAmount",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(True);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"PriceIncludesVAT",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	RuleOfFillingInWithoutDoubleChecking = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithoutDoubleChecking.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	RuleOfFillingInWithReVerification = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithReVerification.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ValidityPeriod",
		"performanceDate",
		RuleOfFillingInWithReVerification);
	
	// Table "Goods and services" - "Goods"
	RuleOfFillingInWithReVerification.ToUpdate_1IS = False;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Goods",
		"productRows.rows",
		RuleOfFillingInWithReVerification);
	
	RuleOfFillingInWithReVerification.TableIS = "Goods";
	RuleOfFillingInWithReVerification.TableBefore = "productRows.rows";
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Products",
		"product",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Price",
		"price",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Count",
		"quantity",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"UnitOfMeasure",
		"measurementUnit",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"VATAmount",
		"VAT",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Sum",
		"total",
		RuleOfFillingInWithReVerification);
	
	// The VAT rate in loading and unloading will be filled in differently
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("Goods.VATRate");
	FillingRule.TableBefore = "productRows.rows";
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"VATRate",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(Catalogs.VATRates.EXCLUDINGVAT);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "Goods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"VATRate",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Printed form
	NewRow = Rule.AttachedPrintedForms.Add();
	NewRow.CommandName = "CommercialProposalForCustomer";
	NewRow.PrintManager = "Document.CommercialProposalForCustomer";
	NewRow.ShouldUpdate = True;
	NewRow.CommandPresentation = NStr("vi = 'Báo giá cho khách hàng (có chiết khấu)';
										|ru = 'Коммерческое предложение клиенту (со скидками)';
										|en = 'Sales quotation (with discounts)'; fa = 'Sales quotation (with discounts)';
										|it = 'Offerta commerciale al cliente (con sconti)';
										|pl = 'Oferta handlowa klientowi (z rabatami)';
										|tr = 'Satış teklifi (indirimli)'");
	
EndProcedure

Procedure AddCustomerOrderIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"sum",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInAmountFromOrder"]));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInVATFromOrder"]));
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("sum");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"DocumentAmount",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(True);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"PriceIncludesVAT",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Approved",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	RuleOfFillingInWithoutDoubleChecking = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithoutDoubleChecking.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	RuleOfFillingInWithReVerification = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithReVerification.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Department",
		"subdivision",
		RuleOfFillingInWithReVerification);
	
	// Table "Goods and services" - "Goods"
	RuleOfFillingInWithReVerification.ToUpdate_1IS = False;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Goods",
		"productRows.rows",
		RuleOfFillingInWithReVerification);
	
	RuleOfFillingInWithReVerification.TableIS = "Goods";
	RuleOfFillingInWithReVerification.TableBefore = "productRows.rows";
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Products",
		"product",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Price",
		"price",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Count",
		"quantity",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"VATAmount",
		"VAT",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Sum",
		"total",
		RuleOfFillingInWithReVerification);
	
	// The VAT rate in loading and unloading will be filled in differently
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("Goods.VATRate");
	FillingRule.TableBefore = "productRows.rows";
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"VATRate",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(Catalogs.VATRates.EXCLUDINGVAT);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "Goods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"VATRate",
		FillingRule);
	
	// You also need to fill in the number of packages
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("productRows.rows.quantity");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "Goods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"NumberOfPackages",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Printed form
	NewRow = Rule.AttachedPrintedForms.Add();
	NewRow.CommandName = "SalesOrder";
	NewRow.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
	NewRow.ShouldUpdate = True;
	NewRow.CommandPresentation = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Müşteri siparişi'");
	
EndProcedure

Procedure AddOrderToSupplierIntegrationRule(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"sum",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInAmountFromOrder"]));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInVATFromOrder"]));
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("sum");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"DocumentAmount",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(True);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"PriceIncludesVAT",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Approved",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	RuleOfFillingInWithoutDoubleChecking = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithoutDoubleChecking.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	RuleOfFillingInWithReVerification = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithReVerification.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Department",
		"subdivision",
		RuleOfFillingInWithReVerification);
	
	// Table "Goods and services" - "Goods"
	RuleOfFillingInWithReVerification.ToUpdate_1IS = False;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Goods",
		"productRows.rows",
		RuleOfFillingInWithReVerification);
	
	RuleOfFillingInWithReVerification.TableIS = "Goods";
	RuleOfFillingInWithReVerification.TableBefore = "productRows.rows";
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Products",
		"product",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Price",
		"price",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Count",
		"quantity",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"VATAmount",
		"VAT",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Sum",
		"total",
		RuleOfFillingInWithReVerification);
	
	// The VAT rate in loading and unloading will be filled in differently
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("Goods.VATRate");
	FillingRule.TableBefore = "productRows.rows";
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"VATRate",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(Catalogs.VATRates.EXCLUDINGVAT);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "Goods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"VATRate",
		FillingRule);
	
	// You also need to fill in the number of packages
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("productRows.rows.quantity");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "Goods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"NumberOfPackages",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Printed form
	NewRow = Rule.AttachedPrintedForms.Add();
	NewRow.CommandName = "PurchaseOrder";
	NewRow.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
	NewRow.ShouldUpdate = True;
	NewRow.CommandPresentation = NStr("vi = 'Đơn hàng đặt nhà cung cấp';
										|ru = 'Заказ поставщику';
										|en = 'Purchase order'; fa = 'سفارش خرید';
										|it = 'Ordine al fornitore';
										|pl = 'Zamówienie do dostawcy';
										|tr = 'Satın alma siparişi'");
	
EndProcedure

Procedure AddIntegrationRuleRequestForReturnOfGoodsFromClient(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("Manager"));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"sum",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInAmountFromReturnRequest"]));
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInVATFromReturnRequest"]));
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("sum");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"DocumentAmount",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(True);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"PriceIncludesVAT",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("statusApproval");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Approved",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	RuleOfFillingInWithoutDoubleChecking = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithoutDoubleChecking.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	RuleOfFillingInWithReVerification = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	RuleOfFillingInWithReVerification.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Manager",
		"responsible",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ContactPerson",
		"contactPerson",
		RuleOfFillingInWithoutDoubleChecking);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Department",
		"subdivision",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"RequestedDeliveryDate",
		"performanceDate",
		RuleOfFillingInWithReVerification);
	
	// Table "Goods and services" - "Returned goods"
	RuleOfFillingInWithReVerification.ToUpdate_1IS = False;
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"ReturnedGoods",
		"productRows.rows",
		RuleOfFillingInWithReVerification);
	
	RuleOfFillingInWithReVerification.TableIS = "ReturnedGoods";
	RuleOfFillingInWithReVerification.TableBefore = "productRows.rows";
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Products",
		"product",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Price",
		"price",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Count",
		"quantity",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"VATAmount",
		"VAT",
		RuleOfFillingInWithReVerification);
	
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Sum",
		"total",
		RuleOfFillingInWithReVerification);
	
	// The VAT rate in loading and unloading will be filled in differently
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("ReturnedGoods.VATRate");
	FillingRule.TableBefore = "productRows.rows";
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"VATRate",
		FillingRule);
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes(Catalogs.VATRates.EXCLUDINGVAT);
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "ReturnedGoods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue,
		"VATRate",
		FillingRule);
	
	// You also need to fill in the number of packages
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("productRows.rows.quantity");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	FillingRule.TableIS = "ReturnedGoods";
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"NumberOfPackages",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Printed form
	NewRow = Rule.AttachedPrintedForms.Add();
	NewRow.CommandName = "ReturnRequest";
	NewRow.PrintManager = "Document.RequestForReturnOfGoodsFromCustomer";
	NewRow.ShouldUpdate = True;
	NewRow.CommandPresentation = NStr("vi = 'Giấy đề nghị trả hàng';
										|ru = 'Заявка на возврат';
										|en = 'Return request'; fa = 'درخواست برگشت';
										|it = 'Domanda di reso';
										|pl = 'Wniosek o zwrot pieniędzy';
										|tr = 'İade talebi'");
	
EndProcedure

Procedure SupplementRuleOfIntegrationApplicationForSpendingMoney(RulesForIntegrationManager, Rule, ExpressionTemplates)
	
	//////////////////////////////////////////////////////
	// Rules of unloading (Transfer to 1C:Document flow)
	
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"author",
		RulesForIntegrationManager.NewRuleForFillingInAttributes("WhoStated"));
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"VAT",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInVATFromCashExpenseRequest"]));
	
	// Table of the DDS Article
	RulesForIntegrationManager.AddAttributeFillingRuleDM(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression,
		"cashFlowRows.rows",
		RulesForIntegrationManager.NewRuleForFillingInAttributes(ExpressionTemplates["FillingInArticlesDDSvTO"]));
	
	//////////////////////////////////////////////////////
	// Loading rules (Getting from 1C:Document management)
	
	// Table "Cash flow items" - "Payment transcript"
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("cashFlowRows.rows");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"ARAPDetails",
		FillingRule);
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("cashFlowRows.rows.item");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.TableIS = "ARAPDetails";
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"CashFlowItem",
		FillingRule);
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("cashFlowRows.rows.total");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.TableIS = "ARAPDetails";
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"Sum",
		FillingRule);
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes("cashFlowRows.rows.VAT");
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	FillingRule.TableIS = "ARAPDetails";
	FillingRule.ToUpdate_1IS = False;
	RulesForIntegrationManager.AddAttributeFillingRuleIS(
		Rule,
		Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute,
		"VATAmount",
		FillingRule);
	
	//////////////////////////////////////////////////////
	// Pair rules
	
	FillingRule = RulesForIntegrationManager.NewRuleForFillingInAttributes();
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP") Then
		RulesForIntegrationManager.AddPairRule(
			Rule,
			"Counterparty",
			"recipient",
			FillingRule);
	EndIf;
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"DocumentAmount",
		"sum",
		FillingRule);
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Currency",
		"currency",
		FillingRule);
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"Department",
		"subdivision",
		FillingRule);
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"RequiredPaymentDate",
		"performanceDate",
		FillingRule);
	
	FillingRule.ChangeMode =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	RulesForIntegrationManager.AddPairRule(
		Rule,
		"WhoStated",
		"responsible",
		FillingRule);
	
EndProcedure

#EndRegion