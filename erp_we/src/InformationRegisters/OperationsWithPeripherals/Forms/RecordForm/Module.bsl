#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OriginalIncomingParameters = True;
	OriginalOutgoingParameters = True;
	FillParameters_();
	If Record.Result Then
		Operation = Record.Operation;
	Else
		Operation = StrTemplate(NStr("vi = '%1 (lỗi thực hiện)';
									|ru = '%1 (ошибка выполнения)';
									|en = '%1 (error)'; fa = '%1 (error)';
									|it = '%1 (ошибка выполнения)';
									|pl = '%1 (error)';
									|tr = '%1 (gerçekleştirme hatası)'"), Record.Operation);
	EndIf;
	
	If Record.Result Then
		Items.ErrorGroup.Visible = False;
	EndIf;
	
	Items.FormMessageToTechSupport.Visible = CommonCEL.UsedMessagesToTechnicalSupportService()
			And CommonCELInternalServerCall.AuthenticationDataOfOnlineSupportUserFilled();
			
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OriginalIncomingParametersOnChange(Item)
	If OriginalIncomingParameters Then
		IncomingParameters = IncomingParametersFormat;
	Else
		IncomingParameters = IncomingParametersOriginal;
	EndIf;
EndProcedure

&AtClient
Procedure OriginalOutgoingParametersOnChange(Item)
	If OriginalOutgoingParameters Then
		OutgoingParameters = OutgoingParametersFormat;
	Else
		OutgoingParameters = OutgoingParametersOriginal;
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillParameters_()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.IncomingParameters AS IncomingParameters,
		|	OperationsWithPeripherals.OutgoingParameters AS OutgoingParameters,
		|	OperationsWithPeripherals.ErrorText AS ErrorText
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	OperationsWithPeripherals.Equipment = &Equipment
		|	AND OperationsWithPeripherals.Date = &Date
		|	AND OperationsWithPeripherals.OperationNumber = &OperationNumber
		|	AND OperationsWithPeripherals.YearMonth = &YearMonth";
	
	Query.SetParameter("YearMonth", Record.YearMonth);
	Query.SetParameter("Date", Record.Date);
	Query.SetParameter("OperationNumber", Record.OperationNumber);
	Query.SetParameter("Equipment", Record.Equipment);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		If ValueIsFilled(Record.IncomingParametersString) Then
			IncomingParametersOriginal = Record.IncomingParametersString;
		Else
			IncomingParametersOriginal = Selection.IncomingParameters.Get();
		EndIf;
		
		If ValueIsFilled(IncomingParametersOriginal) Then
			IncomingParametersFormat = LoggingOfCELOperations.FormatOfLoggingParameter(IncomingParametersOriginal);
			IncomingParameters = IncomingParametersFormat;
		Else
			Items.OriginalIncomingParameters.Visible = False;
			IncomingParameters = IncomingParametersOriginal;
		EndIf;
		

		If ValueIsFilled(Record.OutgoingParametersString) Then
			OutgoingParametersOriginal = Record.OutgoingParametersString;
		Else
			OutgoingParametersOriginal = Selection.OutgoingParameters.Get();
		EndIf;
		
		If ValueIsFilled(OutgoingParametersOriginal) Then
			OutgoingParametersFormat = LoggingOfCELOperations.FormatOfLoggingParameter(OutgoingParametersOriginal);
			OutgoingParameters = OutgoingParametersFormat;
		Else
			Items.OriginalOutgoingParameters.Visible = False;
			OutgoingParameters = OutgoingParametersOriginal;
		EndIf;
		
		If ValueIsFilled(Record.ErrorTextString) Then
			ErrorText = Record.ErrorTextString;
		Else
			ErrorText = Selection.ErrorText.Get();
		EndIf;
		
	EndDo;
	
	
EndProcedure

#EndRegion

