#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement
		And SalesOpportunityStages.Count() = 0 Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Cần xác định các giai đoạn trong quy trình';
				|ru = 'Необходимо определить этапы процесса';
				|en = 'Specify the process stages'; fa = 'Specify the process stages';
				|it = 'È necessario determinare le fasi del processo';
				|pl = 'Należy określić etapy procesu';
				|tr = 'Süreç aşamalarının tanımlanması gerekmektedir'"),
			ThisObject,
			"SalesOpportunityStages",
			,
			Cancel);
	EndIf;

EndProcedure

#EndRegion

#EndIf