#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in information about the participants of the transaction - used when working with interactions.
//
// Parameters:
//  Contacts - Array - list of partners and contact persons involved in the transaction.
//
Procedure FillContacts(Contacts) Export

	If (Not ValueIsFilled(Contacts)) Or (Contacts.Count() = 0) Then
		Return;
	EndIf;

	TabZn = New ValueTable;
	TabZn.Columns.Add("Number", New TypeDescription("Number"));
	TabZn.Columns.Add(
		"Contact",
		New TypeDescription("CatalogRef.Partners,CatalogRef.ContactPersonsForPartners"));

	Number = 0;
	For Each Item In Contacts Do
		Number = Number + 1;
		Contact = ?(TypeOf(Item) = Type("Structure"), Item.Contact, Item);
		NwRw = TabZn.Add();
		NwRw.Number = Number;
		NwRw.Contact = Contact;
	EndDo;

	Query = New Query;
	Query.Text =
		"SELECT
		|	TabZn.Number,
		|	TabZn.Contact
		|INTO VremContacts
		|FROM
		|	&TabZn AS TabZn
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Tab.Partner,
		|	Tab.ContactPerson
		|FROM
		|	(SELECT
		|		VremContacts.Number AS Number,
		|		ContactPersonsForPartners.Owner AS Partner,
		|		ContactPersonsForPartners.Ref AS ContactPerson
		|	FROM
		|		VremContacts AS VremContacts
		|			INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|			ON VremContacts.Contact = ContactPersonsForPartners.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VremContacts.Number,
		|		Partners.Ref,
		|		NULL
		|	FROM
		|		VremContacts AS VremContacts
		|			INNER JOIN Catalog.Partners AS Partners
		|			ON VremContacts.Contact = Partners.Ref) AS Tab
		|
		|ORDER BY
		|	Tab.Number";

	Query.SetParameter("TabZn", TabZn);
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		NwRw = PartnersAndContactPersons.Add();
		NwRw.Partner = Selection.Partner;
		NwRw.ContactPerson = Selection.ContactPerson;

		If ValueIsFilled(Selection.Partner) And Not ValueIsFilled(Partner) Then
			Partner = Selection.Partner;
			If GetFunctionalOption("UseRolesOfPartnersAndContactPersonsInSalesOpportunitiesAndProjects") Then
				NwRw.PartnerSRole = Catalogs.PartnerRolesInSalesOpportunitiesAndProjects.Client;
			EndIf;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData <> Undefined And TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Closed_") Then
			FillingData.Closed_ = False;
		EndIf;
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	Status        = Enums.OpportunityStatuses.InProgress;
	StartDate    = CurrentSessionDate();
	
	If TypeOf(FillingData) = Type("CatalogRef.Partners") Then
		// a transaction based on a partner
		Partner = FillingData;
		SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		
	Else
		
		If TypeOf(FillingData) = Type("CatalogRef.ContactPersonsForPartners") Then
			
			Query = New Query;
			Query.Text = "
			|SELECT
			|	Partners.Client,
			|	Partners.Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	Partners.Ref IN
			|			(SELECT
			|				ContactPersonsForPartners.Owner
			|			FROM
			|				Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|			WHERE
			|				ContactPersonsForPartners.Ref = &ContactPerson)";
			
			Query.SetParameter("ContactPerson", FillingData);
			
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				
				If Not Selection.Client Then
					
					ErrorText = NStr("vi = '%ContactPerson% không phải là người liên hệ của bạn hàng - khách hàng. Chỉ có thể nhập vụ việc trên cơ sở đối với khách hàng.';
									|ru = '%ContactPerson% не является контактным лицом партнера - клиента. Ввод сделки на основании доступен только для клиента.';
									|en = '%ContactPerson% is not a contact person of a customer. Generating a sales opportunity from base documents is available only for customers.'; fa = '%ContactPerson% is not a contact person of a customer. Generating a sales opportunity from base documents is available only for customers.';
									|it = '%ContactPerson% non è la persona di riferimento del partner - cliente. L''immissione della transazione in base alla causale è disponibile solo per il cliente.';
									|pl = '%ContactPerson% nie jest osobą kontaktową partnera - klienta. Wprowadzenie umowy na podstawie jest dostępne tylko dla klienta.';
									|tr = '%ContactPerson%, iş ortağı müşterisinin irtibat kişisi değildir. Satış fırsatı temelinde giriş sadece müşteriye açıktır.'");
					ErrorText = StrReplace(ErrorText, "%ContactPerson%", FillingData);
					
					Raise ErrorText;
					
				Else
					
					Partner = Selection.Ref;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		Interactions.FillDefaultAttributes(ThisObject, FillingData);
		
		If ValueIsFilled(Partner) Then
			SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		
		FillIn_TermsOfSales();
		
	EndIf;
	
	PrimaryDemandCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(PrimaryDemandCurrency);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	NotCheckedAttributeArray = New Array;
	
	// exclude shipping ban segment partners
	If SegmentsServer.PartnerIsIncludedInShipmentBanSegments(Partner)
	 And Not UserRightsCached.SaleToPartnersIncludedInShipmentProhibitionSegments() Then
		MessageText = NStr("vi = 'Không thể ký kết vụ việc với bạn hàng này, vì họ thuộc phân khúc cấm bán hàng.';
							|ru = 'С этим партнером нельзя заключить сделку, так как он входит в сегмент, которому запрещены отгрузки.';
							|en = 'You cannot start a sales opportunity with this partner as they are included in the segment with shipment restrictions.'; fa = 'You cannot start a sales opportunity with this partner as they are included in the segment with shipment restrictions.';
							|it = 'Non è possibile fare un accordo con questo partner perché appartiene al segmento a cui le spedizioni sono proibite.';
							|pl = 'Z tym partnerem nie można zawrzeć umowy, ponieważ wchodzi on w skład segmentu, wysyłki do którego są zabronione.';
							|tr = 'Bu iş ortağıyla, sevkiyat engeli olan bir segmente ait olduğu için satış fırsatı yapılamaz.'");
		
		CommonClientServer.MessageToUser(
			MessageText, ThisObject, "Partner",, Cancel);
	EndIf;

	// check the completeness of the information when losing
	If Status = Enums.OpportunityStatuses.Lost Then
		
		// check the definition of a competitor
		If ReasonForLosingSalesOpportunity = Catalogs.ReasonsForLosingSalesOpportunities.LosingToACompetitor
			And PartnersAndContactPersons.FindRows(
			New Structure("SalesOpportunityWinner",True)).Count() = 0 Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Cần chỉ ra đối thủ cạnh tranh gây thất bại vụ việc ';
					|ru = 'Необходимо указать конкурента, которому проиграна сделка';
					|en = 'Specify a competitor who won the sales opportunity'; fa = 'Specify a competitor who won the sales opportunity';
					|it = 'È necessario specificare il contraente al quale è stata persa la transazione';
					|pl = 'Należy wskazać konkurenta, który wygrał umowę';
					|tr = 'Satış fırsatının kaybedildiği rakibi belirtmeniz gerekmektedir'"),
				ThisObject,
				"PartnersAndContactPersons",, Cancel);
		EndIf;
		
	Else
		
		NotCheckedAttributeArray.Add("ReasonForLosingSalesOpportunity");
		
	EndIf;
	
	ProcessesAreUsed = GetFunctionalOption("UseOpportunityManagement");
	PrimaryDemandIsNotUsed = False;
	
	AttributesOfTransactionType = Common.ObjectAttributesValues(SalesOpportunityKind, "RecordPrimaryDemand, SalesOpportunityType");
	
	If GetFunctionalOption("UsePrimaryDemand") Then
		If ProcessesAreUsed And (SalesOpportunityKind.IsEmpty() Or Not AttributesOfTransactionType.RecordPrimaryDemand) Then
			PrimaryDemandIsNotUsed = True;
		EndIf;
	Else
		PrimaryDemandIsNotUsed = True;
	EndIf;
	
	If PrimaryDemandIsNotUsed Then
		NotCheckedAttributeArray.Add("PrimaryDemandCurrency");
		NotCheckedAttributeArray.Add("PrimaryDemand");
		If PrimaryDemand.Count() > 0 Then
			PrimaryDemand.Clear();
		EndIf;
	EndIf;
	
	If SalesOpportunityKind.IsEmpty() Or AttributesOfTransactionType.SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.StandardSale Then
		NotCheckedAttributeArray.Add("EmployeeResponsible");
	EndIf;
	
	NotCheckedAttributeArray.Add("PrimaryDemand.ReasonForNonFulfillment");
	
	// We will check the indication of satisfaction of the primary demand and the reasons for dissatisfaction, if such are necessary.
	If GetFunctionalOption("UsePrimaryDemand") And (Not ProcessesAreUsed) Or (Not SalesOpportunityKind.IsEmpty() And AttributesOfTransactionType.RecordPrimaryDemand) Then
		If Status = Enums.OpportunityStatuses.Lost Or  Status = Enums.OpportunityStatuses.Won Then
			For Each PrimaryDemandLine In PrimaryDemand Do
				If PrimaryDemandLine.SatisfactionPercentage < 100 And Not ValueIsFilled(PrimaryDemandLine.ReasonForNonFulfillment)Then
					Cancel = True;
					CommonClientServer.MessageToUser(
					NStr("vi = 'Cần chỉ ra nguyên nhân không đảm bảo nhu cầu ban đầu';
						|ru = 'Необходимо указать причину неудовлетворения первичного спроса';
						|en = 'Specify a reason for primary demand non-fulfillment'; fa = 'Specify a reason for primary demand non-fulfillment';
						|it = 'È necessario indicare il motivo della mancata soddisfazione della domanda primaria';
						|pl = 'Należy wskazać przyczynę niezaspokojenia zapotrzebowania początkowego';
						|tr = 'Birincil talebin karşılanamama nedenini belirtmeniz gerekmektedir'"),
					ThisObject,
					"PrimaryDemand[" + String((PrimaryDemandLine.LineNumber-1))+ "].ReasonForNonFulfillment",, Cancel);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	SetPrivilegedMode(True);
	
	// adjust transaction statistics
	SalesOpportunityType = Common.ObjectAttributeValue(SalesOpportunityKind, "SalesOpportunityType");
	If GetFunctionalOption("UseOpportunityManagement")
	   And SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.OtherNonProcessSalesOpportunities Then

		// to clarify the potential sale amount
		If PotentialSaleAmount <> PotentialSaleAmount Then
			Selection = InformationRegisters.StatisticsOfCustomerOpportunities.Select(New Structure("SalesOpportunity", Ref));
			While Selection.Next() Do
				Record = Selection.GetRecordManager();
				Record.Potential = PotentialSaleAmount;
				Record.Write();
			EndDo;
		EndIf;

		// fix status change
		CurrentStep = SalesOpportunitiesServer.GetCurStage(Ref);
		If Status <> Status
		   And CurrentStep <> Catalogs.ProcessesStates.EmptyRef() Then
			If Status = Enums.OpportunityStatuses.Lost Then

				// fix a loss on a process controlled "manually"
				Record = SalesOpportunitiesServer.GetStatisticsRecord(Ref, CurrentStep);
				Record.Result = Enums.OpportunityStatuses.Lost;
				Record.EndDate = CurrentSessionDate();
				Record.Write();

			ElsIf Status = Enums.OpportunityStatuses.Won Then

				CancelingLoss = (Status = Enums.OpportunityStatuses.Lost);
				
				// to fix the winnings according to the process controlled "manually"
				SalesOpportunitiesServer.CloseStatistics(Ref, CurrentStep, CancelingLoss);
			Else

				// cancel the registration of a win/loss by a process controlled "manually"
				Record = SalesOpportunitiesServer.GetStatisticsRecord(Ref, CurrentStep);
				Record.Result = Enums.OpportunityStatuses.InProgress;
				Record.EndDate = '0001.01.01';
				Record.Write();
			EndIf;
		EndIf;//fix status change
	EndIf;//adjust transaction statistics
	
	If Closed_ And Not ValueIsFilled(EndDate) Then
		EndDate = CurrentSessionDate();
	EndIf;
	
	If Status <> Enums.OpportunityStatuses.Lost Then
		
		FoundRows = PartnersAndContactPersons.FindRows(New Structure("SalesOpportunityWinner",True));
		For Each FoundRow In FoundRows Do
			
			FoundRow.SalesOpportunityWinner = False;
			
		EndDo;
	EndIf;
	
	ProcessChangeToDeleteTag();
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
EndProcedure

Procedure OnCopy(CopiedObject)

	EmployeeResponsible 					= Users.CurrentUser();
	Status        					= Enums.OpportunityStatuses.InProgress;
	StartDate    					= CurrentSessionDate();
	EndDate					= Date(1,1,1);
	Closed_       					= False;
	ManualControlEnabled	= False;
	ReasonForLosingSalesOpportunity 			= Catalogs.ReasonsForLosingSalesOpportunities.EmptyRef();	

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.SetActiveFlag(Ref,(Not Closed_) And (Not DeletionMark));
	
	TMCommonUse.SyncKeys(ThisObject);	
	
	If Closed_
		And ValueIsFilled(SalesOpportunityKind)
		And Common.ObjectAttributeValue(SalesOpportunityKind, "SalesOpportunityType") = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement Then
		
		CloseTransactionStages();
		
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

// Fills in sets of table access values 
// 
// Parameters:
// 	Table - ValueTable - table sets of values for the access.
//
Procedure FillAccessValuesSets(Table) Export

	TabRow = Table.Add();
	If ValueIsFilled(Partner) Then
		TabRow.AccessValue = Partner;
	Else
		// Always allowed.
		TabRow.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
	EndIf;

EndProcedure // Fill in the set of access values()

Procedure ProcessChangeToDeleteTag()
	
	If Ref.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	SalesOpportunitiesToCustomer.DeletionMark,
	               |	ISNULL(CustomerOpportunityKinds.SalesOpportunityType, UNDEFINED) AS SalesOpportunityType
	               |FROM
	               |	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	               |		LEFT JOIN Catalog.CustomerOpportunityKinds AS CustomerOpportunityKinds
	               |		ON SalesOpportunitiesToCustomer.SalesOpportunityKind = CustomerOpportunityKinds.Ref
	               |WHERE
	               |	SalesOpportunitiesToCustomer.Ref = &Ref";
	
	Query.SetParameter("Ref",Ref);
	
	Selection = Query.Execute().Select();
    Selection.Next();
	
	If DeletionMark = Selection.DeletionMark Or Selection.SalesOpportunityType <> Enums.TypesOfCustomerOpportunities.StandardSale Then
		Return;	
	EndIf;
	
	If DeletionMark Then
		
		Query = New Query;
		Query.Text = "SELECT
		|	StandardSale.Ref
		|FROM
		|	BusinessProcess.StandardSale AS StandardSale
		|WHERE
		|	StandardSale.SubjectOf = &SalesOpportunity";
		
		Query.SetParameter("SalesOpportunity",Ref);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			Selection.Ref.GetObject().SetDeletionMark(True); 			
			
		EndDo;		
		
	Else 
		
		SalesOpportunitiesServer.CompleteSaleProcess(Ref, Common.ObjectAttributeValue(SalesOpportunityKind, "SalesOpportunityType"));
		ManualControlEnabled = True;
	
	EndIf;	
	
EndProcedure

Procedure FillIn_TermsOfSales()
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED TOP 1
	|	TermsOfSale.Ref AS Terms
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	AND TermsOfSale.Standard_
	|	AND NOT TermsOfSale.DeletionMark";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		CustomerTermsOfSales = Selection.Terms;
		
	EndIf;
EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	
	Return Result;
	
EndFunction

Procedure CloseTransactionStages()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerOpportunityKindsSalesOpportunityStages.SaleProcessStage AS ProcessStep,
	|	StatisticsOfCustomerOpportunities.StartDate                        AS StartDate,
	|	StatisticsOfCustomerOpportunities.SalesOpportunity                            AS SalesOpportunity,
	|	StatisticsOfCustomerOpportunities.EndDate                     AS EndDate,
	|	StatisticsOfCustomerOpportunities.Duration                 AS Duration,
	|	StatisticsOfCustomerOpportunities.Potential                         AS Potential,
	|	StatisticsOfCustomerOpportunities.Result                         AS Result,
	|	StatisticsOfCustomerOpportunities.EmployeeResponsible                     AS EmployeeResponsible
	|FROM
	|	Catalog.CustomerOpportunityKinds.SalesOpportunityStages AS CustomerOpportunityKindsSalesOpportunityStages
	|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON CustomerOpportunityKindsSalesOpportunityStages.Ref = SalesOpportunitiesToCustomer.SalesOpportunityKind
	|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|		ON CustomerOpportunityKindsSalesOpportunityStages.SaleProcessStage = StatisticsOfCustomerOpportunities.ProcessStep
	|			AND (StatisticsOfCustomerOpportunities.SalesOpportunity = &SalesOpportunity)
	|WHERE
	|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|ORDER BY
	|	CustomerOpportunityKindsSalesOpportunityStages.LineNumber";
	
	Query.SetParameter("SalesOpportunity", Ref);
	
	StatisticsData = Query.Execute().Unload();
	
	EndDateOfPreviousStage = Date(1,1,1);
	CurrentSessionDate             = CurrentSessionDate();
	HasChanges                 = False;
	
	For Each StatisticsRow In StatisticsData Do
		
		If ValueIsFilled(StatisticsRow.StartDate) 
			And Not ValueIsFilled(StatisticsRow.EndDate) Then
			
			StatisticsRow.EndDate = CurrentSessionDate;
			StatisticsRow.EndDate = CurrentSessionDate;
			
			If ValueIsFilled(EndDateOfPreviousStage) Then
				StatisticsRow.Duration = Int((StatisticsRow.EndDate - EndDateOfPreviousStage) / 86400);
			EndIf;
			
			StatisticsRow.Result      = Status;
			
			HasChanges = True;
			
		ElsIf Not ValueIsFilled(StatisticsRow.StartDate)
			And Not ValueIsFilled(StatisticsRow.EndDate)
			And Status = Enums.OpportunityStatuses.Won Then
			
			StatisticsRow.EndDate = CurrentSessionDate;
			StatisticsRow.StartDate    = CurrentSessionDate;
			StatisticsRow.Potential     = PotentialSaleAmount;
			StatisticsRow.Result     = Enums.OpportunityStatuses.Won;
			StatisticsRow.SalesOpportunity        = Ref;
			
			If EndDateOfPreviousStage <> CurrentSessionDate
				And ValueIsFilled(EndDateOfPreviousStage) Then
				StatisticsRow.Duration = Int((StatisticsRow.EndDate - EndDateOfPreviousStage) / 86400);
			EndIf;
			
			HasChanges = True;
			
		EndIf;
		
		EndDateOfPreviousStage = StatisticsRow.EndDate;
		
	EndDo;
	
	If HasChanges Then
		
		RecordSet = InformationRegisters.StatisticsOfCustomerOpportunities.CreateRecordSet();
		RecordSet.Filter.SalesOpportunity.Set(Ref);
		
		For Each StatisticsRow In StatisticsData Do
			
			If ValueIsFilled(StatisticsRow.SalesOpportunity) Then
				
				SetRecord = RecordSet.Add();
				FillPropertyValues(SetRecord, StatisticsRow);
				
			EndIf;
			
		EndDo;
		
		RecordSet.Write();
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
