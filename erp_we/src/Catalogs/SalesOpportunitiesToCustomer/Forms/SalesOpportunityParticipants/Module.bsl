
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CommonClientServer.SupplementTable(GetFromTempStorage(Parameters.AddressParticipants), Attendees);
	
	Partner   = Parameters.Partner;
	
	FillInLinkTree(Partner, Attendees);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure 

#EndRegion

#Region FormTableItemsEventHandlersLinkTree

&AtClient
Procedure LinkTreeSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	OpenExecute();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenExecute()

	ShowValue(Undefined, Items.LinkTree.CurrentData.Ref);

EndProcedure

&AtClient
Procedure Refresh(Command)
	
	If FormOwner.TransactionParticipantParametersAreChanged Then
		
		FormOwner.TransactionParticipantParametersAreChanged = False;
		Partner = FormOwner.Object.Partner;
		Attendees.Clear();
		CommonClientServer.SupplementTable(FormOwner.Object.PartnersAndContactPersons, Attendees);
		
	EndIf;
	
	FillInLinkTree(Partner,Attendees);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInLinkTree(Val Client, Val Attendees)

	TreeObject = FormAttributeToValue("LinkTree");

	TreeObject.Rows.Clear();
	MParticipants = New Array;
	
	// create a client branch
	CreatePartnerNode(
		TreeObject,
		Client,
		New Array,
		New Array,
		1,
		String(Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Client));
	MParticipants.Add(Client);

	// form branches of other participants
	For Each Member In Attendees Do
		If MParticipants.Find(Member.Partner) = Undefined Then
			CreatePartnerNode(
				TreeObject,
				Member.Partner,
				New Array,
				New Array,
				1,
				String(Member.PartnerSRole));
			MParticipants.Add(Member);
		EndIf;
	EndDo;

	ValueToFormAttribute(TreeObject, "LinkTree");

EndProcedure

&AtServer
Function GetParticipationString(Member)
	
	If Member = Undefined Or Member.IsEmpty() Then
		Return "";
	EndIf;
	
	// calculate the number of participation objects
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(*) AS InInteractions
		|FROM
		|	FilterCriterion.ContactInteractions(&Contact) AS ContactInteractions");
	Query.SetParameter("Contact", Member);
	NumberOfInteractions = Query.Execute().Select();
	NumberOfInteractions.Next();

	If TypeOf(Member) = Type("CatalogRef.Persons") Then
		Result = ?(
			NumberOfInteractions.InInteractions > 0,
			" " - NStr("vi = '(tương tác: %CntOfInteractions%)';
						|ru = '(взаимодействий : %CntOfInteractions%)';
						|en = '(interactions : %CntOfInteractions%)'; fa = '(interactions : %CntOfInteractions%)';
						|it = '(interazioni : %CntOfInteractions%)';
						|pl = '(interakcji : %CntOfInteractions%)';
						|tr = '(etkileşim : %CntOfInteractions%)'"),
			"");
		Result = StrReplace(
			Result, "%CntOfInteractions%", NumberOfInteractions.InInteractions);
	Else
		Query = New Query(
			"SELECT ALLOWED
			|	COUNT(*) AS InTransactions
			|FROM
			|	FilterCriterion.ParticipationInSalesOpportunities(&Member) AS ParticipationInSalesOpportunities
			|WHERE
			|	(NOT ParticipationInSalesOpportunities.Ref.DeletionMark)");
		Query.SetParameter("Member", Member);
		TransactionNumber = Query.Execute().Select();
		TransactionNumber.Next();
		If TransactionNumber.InTransactions > 0 Then
			Result = " " + ?(
				NumberOfInteractions.InInteractions > 0,
				NStr("vi = '(vụ việc : %NumberOfTransactions%, tương tác - %CntOfInteractions%)';
					|ru = '(сделок : %NumberOfTransactions%, взаимодействий - %CntOfInteractions%)';
					|en = '(sales opportunities : %NumberOfTransactions%, interactions - %CntOfInteractions%)'; fa = '(sales opportunities : %NumberOfTransactions%, interactions - %CntOfInteractions%)';
					|it = '(transazioni : %NumberOfTransactions%, interazioni - %CntOfInteractions%)';
					|pl = '(transakcji : %NumberOfTransactions%, interakcji - %CntOfInteractions%)';
					|tr = '(satış fırsatı : %NumberOfTransactions%, etkileşim - %CntOfInteractions%)'"),
				NStr("vi = '(vụ việc : %NumberOfTransactions%)';
					|ru = '(сделок : %NumberOfTransactions%)';
					|en = '(sales opportunities: %NumberOfTransactions%)'; fa = '(sales opportunities: %NumberOfTransactions%)';
					|it = '(transazioni : %NumberOfTransactions%)';
					|pl = '(transakcji : %NumberOfTransactions%)';
					|tr = '(satış fırsatı : %NumberOfTransactions%)'"));
			Result = StrReplace(Result, "%NumberOfTransactions%", TransactionNumber.InTransactions);
		ElsIf NumberOfInteractions.InInteractions > 0 Then
			Result = " " + NStr("vi = '(tương tác: %CntOfInteractions%)';
								|ru = '(взаимодействий : %CntOfInteractions%)';
								|en = '(interactions : %CntOfInteractions%)'; fa = '(interactions : %CntOfInteractions%)';
								|it = '(interazioni : %CntOfInteractions%)';
								|pl = '(interakcji : %CntOfInteractions%)';
								|tr = '(etkileşim : %CntOfInteractions%)'")
		Else
			Result = "";
		EndIf;
		Result = StrReplace(
			Result, "%CntOfInteractions%", NumberOfInteractions.InInteractions);
	EndIf;

	Return Result;

EndFunction

&AtServer
Function CopyArray(SourceArray1)

	Result = New Array;
	For Each Item In SourceArray1 Do
		Result.Add(Item);
	EndDo;
	Return Result;

EndFunction

&AtServer
Procedure FillOutLinksOnRequest(Node, QueryText, Partners, Contacts, HierarchyLevel, RoleDetails = "", AddnlParameter_ = Undefined)

	// create a request and fill in its parameters
	Query = New Query(QueryText);
	Query.SetParameter("Node", Node.Ref);
	If AddnlParameter_ <> Undefined Then
		Query.SetParameter("AddnlParameter_", AddnlParameter_);
	EndIf;
	Query.SetParameter("DateEmpty",Date(1,1,1));
	Query.SetParameter("CurrentDate",CurrentSessionDate());
	List = Query.Execute().Select();

	// create link nodes
	While List.Next() Do
		If List.RefType = Type("CatalogRef.Partners") Then
			CreatePartnerNode(
				Node, List.Ref, Partners, Contacts, HierarchyLevel + 1,
				?(RoleDetails = "", List.Role, RoleDetails));
		ElsIf List.RefType = Type("CatalogRef.ContactPersonsForPartners") Then
			CreateContactPersonNode(
				Node, List.Ref, Partners, Contacts, HierarchyLevel + 1,
				?(RoleDetails = "", List.Role, RoleDetails));
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure CreatePartnerNode(Parent, Partner, ParentSPartners, MContacts, HierarchyLevel, Role = Undefined)

	// limit recursion and depth of analysis
	If ParentSPartners.Find(Partner) <> Undefined
	 Or (AnalysisDepthRestriction > 0 And HierarchyLevel > AnalysisDepthRestriction) Then
		Return;
	EndIf;
	
	// create a partner node
	Partners = CopyArray(ParentSPartners);
	Partners.Add(Partner);
	PartnerNode_ = Parent.Rows.Add();
	PartnerNode_.Ref = Partner;
	PartnerName = Common.ObjectAttributeValue(Partner, "Description"); 
	PartnerNode_.Presentation = ?(
		Not ValueIsFilled(Role) , ?(Partner.IsEmpty(),NStr("vi = '<Chưa chỉ ra>';
															|ru = '<Не указан>';
															|en = '<not specified>'; fa = '<مشخص نشده>';
															|it = '<non specificato>';
															|pl = '<Nie określono>';
															|tr = '<Belirtilmedi>'"),PartnerName),"(" + Role + ") " 
		+ ?(Partner.IsEmpty(),NStr("vi = '<Chưa chỉ ra>';
									|ru = '<Не указан>';
									|en = '<not specified>'; fa = '<مشخص نشده>';
									|it = '<non specificato>';
									|pl = '<Nie określono>';
									|tr = '<Belirtilmedi>'"), PartnerName)
	) + GetParticipationString(Partner);

	// form contacts with the owner's contact persons
	FillOutLinksOnRequest(
		PartnerNode_,
		"SELECT ALLOWED
		|	ContactPersonsForPartners.Ref AS Ref,
		|	ContactPersonsForPartners.Presentation AS Presentation,
		|	VALUETYPE(ContactPersonsForPartners.Ref) AS RefType,
		|	UNDEFINED AS Role
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|WHERE
		|	ContactPersonsForPartners.Owner = &Node
		|	AND (NOT ContactPersonsForPartners.DeletionMark)
		|	AND (ContactPersonsForPartners.RelationEndDate = &DateEmpty
		|			OR ContactPersonsForPartners.RelationEndDate > &CurrentDate)
		|
		|ORDER BY
		|	Presentation",
		Partners,
		MContacts,
		HierarchyLevel);//form contacts with the owner's contact persons

	// form connections with partners through a group
	PartnerSParent = Common.ObjectAttributeValue(Partner, "Parent");
	PartnerGroup_ = PartnerSParent;
	If ValueIsFilled(PartnerGroup_) Then
		CreatePartnerGroupNode(PartnerNode_, PartnerGroup_, Partners, MContacts, HierarchyLevel + 1);
	EndIf;//form connections with partners through a group

	// form connections by primary interest
	FillOutLinksOnRequest(
		PartnerNode_,
		"SELECT ALLOWED TOP 1
		|	SourcesOfInitialRequests.SourceOfInitialRequest AS Ref,
		|	VALUETYPE(SourcesOfInitialRequests.SourceOfInitialRequest) AS RefType
		|FROM
		|	InformationRegister.SourcesOfInitialRequests AS SourcesOfInitialRequests
		|WHERE
		|	SourcesOfInitialRequests.Partner = &Node
		|
		|ORDER BY
		|	SourcesOfInitialRequests.SalesOpportunity.StartDate",
		Partners,
		MContacts,
		HierarchyLevel,
		NStr("vi = 'quan tâm ban đầu';
			|ru = 'первичный интерес';
			|en = 'lead sources'; fa = 'lead sources';
			|it = 'interesse primario';
			|pl = 'zainteresowanie początkowe';
			|tr = 'birincil ilgi'"));//form connections by primary interest

	// form connections with partners defined by the user
	FillOutLinksOnRequest(
		PartnerNode_,
		"SELECT ALLOWED
		|	RelationshipsBetweenPartners12.SecondPartner AS Ref,
		|	RelationshipsBetweenPartners12.SecondPartner.Description AS Presentation,
		|	RelationshipsBetweenPartners12.RelationshipType.PartnerSRole2 AS Role,
		|	VALUETYPE(RelationshipsBetweenPartners12.SecondPartner) AS RefType
		|FROM
		|	InformationRegister.RelationshipsBetweenPartners AS RelationshipsBetweenPartners12
		|WHERE
		|	RelationshipsBetweenPartners12.FirstPartner = &Node
		|
		|UNION ALL
		|
		|SELECT
		|	RelationshipsBetweenPartners21.FirstPartner,
		|	RelationshipsBetweenPartners21.FirstPartner.Description,
		|	RelationshipsBetweenPartners21.RelationshipType.PartnerSRole1,
		|	VALUETYPE(RelationshipsBetweenPartners21.FirstPartner)
		|FROM
		|	InformationRegister.RelationshipsBetweenPartners AS RelationshipsBetweenPartners21
		|WHERE
		|	RelationshipsBetweenPartners21.SecondPartner = &Node",
		Partners,
		MContacts,
		HierarchyLevel);//form connections with partners defined by the user

EndProcedure

&AtServer
Procedure CreatePartnerGroupNode(Parent, PartnerGroup_, ParentSPartners, MContacts, HierarchyLevel)

	// limit recursion and depth of analysis
	If ParentSPartners.Find(PartnerGroup_) <> Undefined
	 Or (AnalysisDepthRestriction > 0 And HierarchyLevel > AnalysisDepthRestriction) Then
		Return;
	EndIf;

	// create a partner group node
	Partners = CopyArray(ParentSPartners);
	Partners.Add(PartnerGroup_);
	PartnerGroupNode = Parent.Rows.Add();
	PartnerGroupNode.Ref = PartnerGroup_;
	PartnerGroupNode.Presentation = "(" + NStr("vi = 'trong nhóm';
												|ru = 'в группе';
												|en = 'in group'; fa = 'in group';
												|it = 'nel gruppo';
												|pl = 'w grupie';
												|tr = 'grupta'") + ") " + String(PartnerGroup_);

	// fill in the partner group node
	FillOutLinksOnRequest(
		PartnerGroupNode,
		"SELECT ALLOWED
		|	Partners.Ref AS Ref,
		|	Partners.Description AS Presentation,
		|	VALUETYPE(Partners.Ref) AS RefType
		|FROM
		|	Catalog.Partners AS Partners
		|WHERE
		|	Partners.Ref <> &Node
		|	AND Partners.Ref IN HIERARCHY(&AddnlParameter_)
		|	AND (NOT Partners.DeletionMark)",
		Partners,
		MContacts,
		HierarchyLevel + 1,
		Undefined,
		PartnerGroup_);//fill in the partner group node

EndProcedure

// Creates a parent row in the tree for the contact's data.
// 
// Parameters:
//  Parent - ValueTreeRow - parent row.
//  ContactPerson - CatalogRef.ContactPersonsForPartners - Contact person
//  Partners - Array - 
//  ParentSContacts - Array - 
//  HierarchyLevel - Number - 
//  Role - Undefined, String - 
//
&AtServer
Procedure CreateContactPersonNode(Parent, ContactPerson, Partners, ParentSContacts, HierarchyLevel, Role = Undefined)

	// limit recursion and depth of analysis
	If ParentSContacts.Find(ContactPerson) <> Undefined
	 Or (AnalysisDepthRestriction > 0 And HierarchyLevel > AnalysisDepthRestriction) Then
		Return;
	EndIf;

	// create a contact person node
	MContacts = CopyArray(ParentSContacts);
	MContacts.Add(ContactPerson);
	ContactPersonNode = Parent.Rows.Add();
	ContactPersonNode["Ref"] = ContactPerson;

	// create a contact person role string
	If Role = Undefined Then
			ContactPersonRoles = "";
			Query = New Query(
				"SELECT ALLOWED
				|	ContactPersonsOfPartnersRoleOfContactPerson.ContactRole.Description AS Role
				|FROM
				|	Catalog.ContactPersonsForPartners.ContactPersonRoles AS ContactPersonsOfPartnersRoleOfContactPerson
				|WHERE
				|	ContactPersonsOfPartnersRoleOfContactPerson.Ref = &ContactPerson");
			Query.SetParameter("ContactPerson", ContactPerson);
			RolesList = Query.Execute().Select();
			While RolesList.Next() Do
				ContactPersonRoles = ContactPersonRoles + ?(
					ContactPersonRoles = "", RolesList.Role, ", " + RolesList.Role);
			EndDo;
		Else
			ContactPersonRoles = Role;
		EndIf; //create a contact person role string
	ContactPersonNode.Presentation = ?(TrimAll(ContactPersonRoles) = "","","(" + ContactPersonRoles + ") ") 
										+ String(ContactPerson) + GetParticipationString(ContactPerson);

	// form connections through primary interest
	FillOutLinksOnRequest(
		ContactPersonNode,
		"SELECT ALLOWED DISTINCT
		|	SourcesOfInitialRequests.Partner AS Ref,
		|	SourcesOfInitialRequests.Partner.Description AS Presentation,
		|	VALUETYPE(SourcesOfInitialRequests.Partner) AS RefType
		|FROM
		|	InformationRegister.SourcesOfInitialRequests AS SourcesOfInitialRequests
		|WHERE
		|	SourcesOfInitialRequests.SourceOfInitialRequest.Ref = &Node",
		Partners,
		MContacts,
		HierarchyLevel,
		NStr("vi = 'quan tâm ban đầu';
			|ru = 'первичный интерес';
			|en = 'lead sources'; fa = 'lead sources';
			|it = 'interesse primario';
			|pl = 'zainteresowanie początkowe';
			|tr = 'birincil ilgi'"));//form connections through primary interest

	// get in touch with the owner
	Query = New Query(
		"SELECT ALLOWED
		|	ContactPersonsForPartners.Owner AS Partner
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|WHERE
		|	ContactPersonsForPartners.Ref = &ContactPerson
		|	AND (NOT ContactPersonsForPartners.DeletionMark)");
	Query.SetParameter("ContactPerson", ContactPerson);
	CommunicationWithOwner = Query.Execute().Select();
	CommunicationWithOwner.Next();//get in touch with the owner

	// add an owner partner line
	If Partners.Find(CommunicationWithOwner.Partner) = Undefined Then
		CreatePartnerNode(
			ContactPersonNode,
			CommunicationWithOwner.Partner,
			Partners,
			MContacts,
			HierarchyLevel,
			NStr("vi = 'bạn hàng';
				|ru = 'партнер';
				|en = 'partner'; fa = 'شریک تجاری';
				|it = 'partner';
				|pl = 'partner';
				|tr = 'iş ortağı'"))
	EndIf;//add an owner partner line

EndProcedure

#EndRegion
