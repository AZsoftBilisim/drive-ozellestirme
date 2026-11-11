#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)

	StandardProcessing = False;
	
	AvailableFormsOfPayment = CashServer.AvailableFormsOfPaymentToChooseFrom();
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(AvailableFormsOfPayment);
	
	ElementAny = ChoiceData.FindByValue(Enums.PaymentForms.EmptyRef());
	
	If ElementAny <> Undefined Then
		ElementAny.Presentation = NStr("ru = 'Любая';
										|vi = 'Any';
										|en = 'Any'; fa = 'هر';
										|it = 'Any';
										|pl = 'Any';
										|tr = 'Herhangi'");
	EndIf;

EndProcedure

#EndRegion

#EndIf