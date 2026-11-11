#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagement.FillAccessValuesSets
// 
// Parameters:
// 	Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	Partner = Undefined;
	
	If ValueIsFilled(SubjectOf) Then
		Partner = Common.ObjectAttributeValue(SubjectOf, "Partner");
	EndIf;
	
	TabRow = Table.Add();
	TabRow.SetNumber = 1;
	TabRow.AccessValue = Partner;
	
	TabRow = Table.Add();
	TabRow.SetNumber = 2;
	TabRow.AccessValue = Author;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure PrimaryContactBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.PrimaryContact);

EndProcedure

Procedure CustomerQualificationsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.CustomerQualifications);

EndProcedure

Procedure ProposalPreparationBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.ProposalGeneration);

EndProcedure

Procedure PresentationBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.Presentation);

EndProcedure

Procedure AuctionBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.HarmonizationOfTerms);

EndProcedure

Procedure ConfirmationOfObligationsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.PreparationForExecutionOfObligations);

EndProcedure

Procedure MonitoringFulfillmentOfObligationsBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	SalesOpportunitiesServer.SetProcessStage(SubjectOf, Catalogs.ProcessesStates.LiabilityFulfillment);

EndProcedure

Procedure FixingResultsOfTransactionWhenExecuting(BusinessProcessRoutePoint, Task, Cancel)
	
	TransactionDetails_ = Common.ObjectAttributesValues(SubjectOf, "Status, ReasonForLosingSalesOpportunity");
	
	If TransactionDetails_.Status = Enums.OpportunityStatuses.Lost Then
		Result = ValueIsFilled(TransactionDetails_.ReasonForLosingSalesOpportunity);
		If Not Result Then
			Common.MessageToUser(
			NStr("vi = 'Để thực hiện nhiệm vụ, cần xác định nguyên nhân thất bại vụ việc';
				|ru = 'Для выполнения задачи необходимо определить причину проигрыша сделки';
				|en = 'To complete the task, determine the sales opportunity loss reason'; fa = 'To complete the task, determine the sales opportunity loss reason';
				|it = 'Per completare il task, è necessario individuare il motivo della perdita della transazione';
				|pl = 'W celu wykonania zadania należy określić przyczynę przegranej umowy';
				|tr = 'Görevi tamamlamak için satış fırsatının kaybedilme nedenini belirlemek gerekir'"));
		EndIf;
	ElsIf TransactionDetails_.Status = Enums.OpportunityStatuses.InProgress Then
		Common.MessageToUser(
			NStr("vi = 'Để thực hiện nhiệm vụ, vụ việc cần nằm ở trạng thái giành được hoặc thất bại.';
				|ru = 'Для выполнения задачи сделка должна находится в статусе выиграна или проиграна.';
				|en = 'To complete the task, set sales opportunity status to Won or Lost.'; fa = 'To complete the task, set sales opportunity status to Won or Lost.';
				|it = 'Per completare il task, la transazione deve essere nello stato di vinto o perso.';
				|pl = 'Aby wykonać zadanie umowa posiadać status wygrana lub przegrana.';
				|tr = 'Görevi tamamlamak için satış fırsatı kazanılmış veya kaybedilmiş durumda olmalıdır.'"));
		Result = False;
	Else
		Result = True;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Result Then
		Query = New Query;
		Query.Text = "SELECT TOP 1
		|	SalesOpportunitiesToCustomerPrimaryDemand.LineNumber AS LineNumber
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer.PrimaryDemand AS SalesOpportunitiesToCustomerPrimaryDemand
		|WHERE
		|	SalesOpportunitiesToCustomerPrimaryDemand.Ref = &SubjectOf
		|	AND SalesOpportunitiesToCustomerPrimaryDemand.SatisfactionPercentage <> 100
		|	AND SalesOpportunitiesToCustomerPrimaryDemand.ReasonForNonFulfillment = VALUE(Catalog.ReasonsForPrimaryDemandNonFulfillment.EmptyRef)";
		
		Query.SetParameter("SubjectOf",SubjectOf);
		
		If Not Query.Execute().IsEmpty() Then
			Common.MessageToUser(
			NStr("vi = 'Để thực hiện nhiệm vụ, cần điền chính xác kết quả đảm bảo nhu cầu ban đầu.';
				|ru = 'Для выполнения задачи необходимо корректно заполнить результаты удовлетворения первичного спроса.';
				|en = 'To execute the task, correctly fill in the results of primary demand fulfillment.'; fa = 'To execute the task, correctly fill in the results of primary demand fulfillment.';
				|it = 'Per completare il task è necessario compilare correttamente i risultati di soddisfazione della domanda primaria.';
				|pl = 'W celu wykonania zadania należy prawidłowo wypełnić rezultaty zaspokojenia początkowego zapotrzebowania.';
				|tr = 'Görevi tamamlamak için, birincil talebi karşılama sonuçlarının doğru şekilde doldurulması gerekir.'"));
			Result = False;
		Else
			Result = True;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	If Result Then
		CloseOpportunity(Cancel);
	Else
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure PrimaryContactOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	If GetFunctionalOption("UseEmailClient") Then
		QueryText =
		"SELECT TOP 1
		|	Interactions.Ref
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|		ON Interactions.Ref = InteractionsFolderSubjects.Interaction
		|WHERE
		|	VALUETYPE(Interactions.Ref) <> TYPE(Document.PlannedInteraction)
		|	AND (NOT Interactions.DeletionMark)
		|	AND InteractionsFolderSubjects.SubjectOf = &FilterRef";
		MessageText =
		NStr("vi = 'Nhiệm vụ không thể được tính là đã thực hiện bởi vì không có tương tác đã ghi nhận';
			|ru = 'Задача не может считаться выполненной, так как нет зарегистрированных взаимодействий.';
			|en = 'Cannot complete the task because no interactions are registered.'; fa = 'Cannot complete the task because no interactions are registered.';
			|it = 'Il task non può essere considerato completato, poiché non ci sono interazioni registrate.';
			|pl = 'Zadanie nie może być uznane za wykonane, ponieważ nie istnieją zarejestrowane interakcje.';
			|tr = 'Kayıtlı etkileşim olmadığı için görev tamamlanmış olarak kabul edilemez.'");
		If Not DocumentCreated(QueryText, SubjectOf, MessageText) Then
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CustomerQualificationsOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	AgreementOfTransaction = Common.ObjectAttributeValue(SubjectOf, "CustomerTermsOfSales");
		
	If ValueIsFilled(AgreementOfTransaction) Then
		Result = True;
	Else
		Result = False;
		CommonClientServer.MessageToUser(
			NStr(
				"vi = 'Nhiệm vụ không thể được tính là đã thực hiện bởi vì chưa xác định thỏa thuận với khách hàng';
				|ru = 'Задача не может считаться выполненной, так как не определено соглашение с клиентом.';
				|en = 'Cannot complete the task because no customer agreement is specified.'; fa = 'Cannot complete the task because no customer agreement is specified.';
				|it = 'Il task non può essere considerato completato, poiché non è definito alcun accordo con il cliente.';
				|pl = 'Zadanie nie może być uznane za wykonane, ponieważ nie określono uzgodnienia z klientem.';
				|tr = 'Satış koşulları tanımlanmadığından görev tamamlanmış olarak kabul edilemez.'"));
	EndIf;
	
	Cancel = Cancel Or Not Result;

EndProcedure

Procedure ProposalPreparationOnExecute(RoutePoint, Task, Cancel)
	
	QueryText =
		"SELECT TOP 1
		|	CommercialProposalForCustomer.Ref
		|FROM
		|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
		|WHERE
		|	CommercialProposalForCustomer.SalesOpportunity = &FilterRef
		|	AND CommercialProposalForCustomer.Posted
		|	AND CommercialProposalForCustomer.Status = VALUE(Enum.StatusesOfCommercialProposalsForCustomers.Valid)
		|	AND (CommercialProposalForCustomer.ValidityPeriod = DATETIME(1, 1, 1)
		|			OR CommercialProposalForCustomer.ValidityPeriod >= &CurrentDate)";
		
	MessageText =
		NStr("vi = 'Nhiệm vụ không thể tính là đã hoàn thành, bởi vì không có báo giá còn hiệu lực theo vụ việc.';
			|ru = 'Задача не может считаться выполненной, так как нет действующего коммерческого предложения по сделке.';
			|en = 'The task cannot be considered completed since there is no valid sales quotation for the sales opportunity.'; fa = 'The task cannot be considered completed since there is no valid sales quotation for the sales opportunity.';
			|it = 'Il task non può essere considerato eseguito, in quanto non esiste un''offerta commerciale valida per la transazione.';
			|pl = 'Zadanie nie może być uważane za zakończone, ponieważ nie ma obowiązującej oferty handlowej dotyczącej transakcji.';
			|tr = 'Satış fırsatı için geçerli satış teklifi olmadığı için görev tamamlanmış olarak kabul edilemez.'");
		
	Result = DocumentCreated(QueryText, SubjectOf, MessageText);

	Cancel = Cancel Or Not Result;

EndProcedure

Procedure CreatingOrderOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	PartnerOfTransaction = Common.ObjectAttributeValue(SubjectOf, "Partner");
	Result = (PartnersAndCounterparties.GetAllPartnersOfPartner(PartnerOfTransaction).Count() > 0);

	If Not Result Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ không thể được tính là đã thực hiện bởi vì chưa xác định đối tác của bạn hàng.';
				|ru = 'Задача не может считаться выполненной, так как не определен контрагент партнера.';
				|en = 'Cannot complete the task because no partner counterparty is specified.'; fa = 'Cannot complete the task because no partner counterparty is specified.';
				|it = 'Il task non può essere considerato completato, poiché non è definito il contraente del partner.';
				|pl = 'Zadanie nie może być uznane za wykonane, ponieważ nie określono kontrahenta partnera.';
				|tr = 'İş ortağının cari hesabı tanımlanmadığından görev tamamlanmış olarak kabul edilemez.'"));
	Else
		QueryText =
			"SELECT TOP 1
			|	SalesOrder.Ref
			|FROM
			|	Document.SalesOrder AS SalesOrder
			|WHERE
			|	SalesOrder.Posted
			|	AND SalesOrder.SalesOpportunity = &FilterRef";
		MessageText =
			NStr("vi = 'Nhiệm vụ không thể coi là đã thực hiện, bởi vì không có đơn hàng của khách.';
				|ru = 'Задача не может считаться выполненной, так как нет заказа клиента.';
				|en = 'Cannot complete the task because no sales order is specified.'; fa = 'Cannot complete the task because no sales order is specified.';
				|it = 'Il task non può essere considerato completato, poiché non esiste un ordine del cliente.';
				|pl = 'Zadanie nie może być uznane za wykonane, ponieważ nie istnieje zamówienie klienta.';
				|tr = 'Müşteri siparişi olmadığı için görev tamamlanmış olarak kabul edilemez.'");
		Result = DocumentCreated(QueryText, SubjectOf, MessageText);
	EndIf;
	
	Cancel = Cancel Or Not Result;
	
EndProcedure

Procedure ConfirmationOfObligationsOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	SetPrivilegedMode(True);
	
	Result = True;
	
	Query = New Query(
		"SELECT TOP 1
		|	SalesOrder.Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Posted
		|	AND SalesOrder.SalesOpportunity = &FilterRef
		|	AND SalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)");
	Query.SetParameter("FilterRef", SubjectOf);
	QueryResult = Query.Execute();
	NoSettlementsUnderContracts = QueryResult.IsEmpty();
	
	If NoSettlementsUnderContracts Then
		
		Query = New Query(
			"SELECT
			|	ISNULL(SettlementsWithCustomersTurnover.SumReceipt, 0) + ISNULL(SettlementsWithCustomersTurnover.SumExpense, 0) + ISNULL(SettlementsWithCustomersTurnover.ToShipReceipt, 0) AS Commitments
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Turnovers(, , , ARAPObject.Object.SalesOpportunity = &FilterRef) AS SettlementsWithCustomersTurnover");
		Query.SetParameter("FilterRef", SubjectOf);
		Selection = Query.Execute().Select();
		Result = Selection.Next() And Selection.Commitments > 0;
		
	EndIf;

	If Not Result Then
		CommonClientServer.MessageToUser(
			NStr(
				"vi = 'Nhiệm vụ không thể tính là đã thực hiện, bởi vì không có trách nhiệm mở theo vụ việc.';
				|ru = 'Задача не может считаться выполненной, так как нет открытых обязательств по сделке.';
				|en = 'Cannot complete the task because the sales opportunity has no open liabilities.'; fa = 'Cannot complete the task because the sales opportunity has no open liabilities.';
				|it = 'Il task non può essere considerato completato, in quanto non ci sono obblighi aperti sulla transazione.';
				|pl = 'Zadanie nie może być uznane za wykonane, ponieważ nie istnieją żadne otwarte zobowiązania w ramach umowy.';
				|tr = 'Satış fırsatı kapsamında açık taahhütler olmadığı için görev tamamlanmış olarak kabul edilemez.'"));
	EndIf;

	Cancel = Cancel Or Not Result;
	
EndProcedure

Procedure MonitoringFulfillmentOfObligationsOnExecute(BusinessProcessRoutePoint, Task, Cancel)
	
	SetPrivilegedMode(True);
	
	Result = True;
	
	Query = New Query(
		"SELECT TOP 1
		|	SalesOrder.Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Posted
		|	AND SalesOrder.SalesOpportunity = &FilterRef
		|	AND SalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)");
	Query.SetParameter("FilterRef", SubjectOf);
	QueryResult = Query.Execute();
	NoSettlementsUnderContracts = QueryResult.IsEmpty();
	
	If NoSettlementsUnderContracts Then
		
		// check payment balances
		Query = New Query(
			"SELECT
			|	ISNULL(CustomersARAPAccountingBalance.SumBalance, 0) AS SumBalance,
			|	ISNULL(CustomersARAPAccountingBalance.AmountDueBalance, 0) AS AmountDueBalance
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(
			|			,
			|			ARAPObject.Object.SalesOpportunity = &SalesOpportunity) AS CustomersARAPAccountingBalance");
		Query.SetParameter("SalesOpportunity", SubjectOf);
		Payments_2Balance = Query.Execute().Select();
		Payments_2Balance.Next();
		Result = Payments_2Balance.SumBalance = 0 And Payments_2Balance.AmountDueBalance = 0;

		// check shipment balances
		Query = New Query;
		Query.Text =
		"SELECT
		|	SUM(ShipmentReferences.QuantityToBeShippedTurnover -
		|		ShipmentReferences.ShippedQuantityTurnover) AS CountBalance
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShipmentReferences
		|HAVING
		|	SUM(ShipmentReferences.QuantityToBeShippedTurnover -
		|		ShipmentReferences.ShippedQuantityTurnover) <> 0";
			
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder.SalesOpportunity = &SalesOpportunity";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToShip, Shipped";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.SetParameter("SalesOpportunity", SubjectOf);
		
		ResultOfRemainder = Query.Execute();
		Result = Result
			And ResultOfRemainder.IsEmpty();
		
	EndIf;

	If Not Result Then
		Common.MessageToUser(
			NStr("vi = 'Nhiệm vụ không thể thực hiện được, bởi vì có nghĩa vụ theo vụ việc chưa được thực hiện';
				|ru = 'Задача не может быть выполнена, так как есть не выполненные обязательства по сделке';
				|en = 'Cannot complete the task because the sales opportunity has unfulfilled liabilities'; fa = 'Cannot complete the task because the sales opportunity has unfulfilled liabilities';
				|it = 'Il task non può essere considerato completato, in quanto vi sono obblighi inadempiuti nell''ambito della transazione';
				|pl = 'Zadanie nie może być uznane za wykonane, ponieważ istnieją niespełnione zobowiązania w ramach umowy';
				|tr = 'Satış fırsatı kapsamında yerine getirilmeyen yükümlülükler olduğundan görev tamamlanamaz'"));
	EndIf;
	
	Cancel = Cancel Or Not Result;
	
EndProcedure

Procedure LostTransactionConditionCheck(BusinessProcessRoutePoint, Result)
	
	StatusOfItem = Common.ObjectAttributeValue(SubjectOf, "Status");
	
	Result = (StatusOfItem = Enums.OpportunityStatuses.Lost);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInTaskWhenCreatingTasks(BusinessProcessRoutePoint, TasksBeingFormed)

	SalesOpportunitiesServer.FillInProcessTaskDetails(
		SubjectOf, BusinessProcesses.StandardSale,
		BusinessProcessRoutePoint,
		TasksBeingFormed);

EndProcedure

Function DocumentCreated(QueryText, Filter, ErrorMessageText_)

	SetPrivilegedMode(True);
	
	Query = New Query(QueryText);
	Query.SetParameter("FilterRef", Filter);
	Query.SetParameter("CurrentDate",BegOfDay(CurrentSessionDate()));
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		CommonClientServer.MessageToUser(ErrorMessageText_);
		Return False;
	EndIf;

	Return True;

EndFunction

Procedure CloseOpportunity(Cancel = False)

	Try
		LockDataForEdit(SubjectOf);
	Except
		
		MessageText = NStr("vi = 'Không thể phong tỏa %SalesOpportunity%.';
							|ru = 'Не удалось заблокировать %SalesOpportunity%.';
							|en = 'Cannot lock %SalesOpportunity%.'; fa = 'Cannot lock %SalesOpportunity%.';
							|it = 'Impossibile bloccare %SalesOpportunity%.';
							|pl = 'Nie udało się zablokować %SalesOpportunity%.';
							|tr = '%SalesOpportunity% engellenemedi.'");
		MessageText = StrReplace(MessageText, "%SalesOpportunity%", SubjectOf);
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
		
		Return;
		
	EndTry;
	
	Try
		TransactionObject               = SubjectOf.GetObject();
		TransactionObject.Closed_       = True;
		TransactionObject.EndDate = CurrentSessionDate();
		TransactionObject.Write();
		
		CurrentStep = SalesOpportunitiesServer.GetCurStage(SubjectOf);
		If  CurrentStep <> Catalogs.ProcessesStates.EmptyRef() Then
				SalesOpportunitiesServer.CloseStatistics(SubjectOf, CurrentStep);
		EndIf;

	Except
		Cancel = True;
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure


#EndRegion

#EndIf
