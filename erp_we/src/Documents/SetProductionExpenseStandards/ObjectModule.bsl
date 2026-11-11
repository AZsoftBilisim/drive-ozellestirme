
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// The expiration date of the agreement must not be less than the start date of the agreement.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hạn phải ít nhất là ngày bắt đầu';
							|ru = 'Дата окончания действия должна быть не меньше даты начала';
							|en = 'Action expiration date should not be less than the action start date'; fa = 'Action expiration date should not be less than the action start date';
							|it = 'La data di fine dell''azione non deve essere precedente alla data di inizio.';
							|pl = 'Data zakończenia musi być nie mniejsza niż data rozpoczęcia';
							|tr = 'Geçerlilik bitiş tarihi, başlangıç tarihinden önce olmamalıdır'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
	EndIf;
	
	If FixedCostRates.Count() = 0 And VariableCostRates.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Định mức của chi phí biến đổi và cố định không được điền';
						|ru = 'Не заполнены нормы переменных и постоянных расходов';
						|en = 'Rates of variable and fixed costs are not specified'; fa = 'Rates of variable and fixed costs are not specified';
						|it = 'Le norme di costi variabili e fissi non sono compilate';
						|pl = 'Nie wypełniono normy kosztów zmiennych i stałych';
						|tr = 'Değişken ve sabit gider oranları doldurulmadı'");
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject, 
			,
			,
			Cancel);
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	If Not ValueIsFilled(ValidityStartDate) Then
		ValidityStartDate		= BegOfMonth(CurrentSessionDate());
	EndIf;
	Author = Users.CurrentUser();
	Organization             = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

#EndRegion

#EndIf
