#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ReadAcceptablePriceRange();
	
	Items.KindOfMaximumAllowablePurchasePrice.ReadOnly = Not AccessRight("Update", Metadata.Constants.KindOfMaximumAllowablePurchasePrice);
	Items.KindOfMaximumAllowableSellingPrices.ReadOnly = Not AccessRight("Update", Metadata.Constants.KindOfMaximumAllowableSellingPrices);
	Items.KindOfMinimumAllowableSellingPrices.ReadOnly  = Not AccessRight("Update", Metadata.Constants.KindOfMinimumAllowableSellingPrices);
	
	ThisObject.ReadOnly = 
		  Items.KindOfMaximumAllowablePurchasePrice.ReadOnly
		And Items.KindOfMaximumAllowableSellingPrices.ReadOnly
		And Items.KindOfMinimumAllowableSellingPrices.ReadOnly;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress And Modified And Not Exit Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại?';
																						|ru = 'Данные изменены. Сохранить?';
																						|en = 'Data is changed. Save?'; fa = 'Data is changed. Save?';
																						|it = 'Dati modificati. Salvare?';
																						|pl = 'Dane zostały zmienione. Zapisać?';
																						|tr = 'Veriler değiştirildi. Kaydedilsin mi?'"),QuestionDialogMode.YesNoCancel);
		
	EndIf;

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		RecordRangeOfAcceptablePrices();
		Close();
	ElsIf UserAnswer = DialogReturnCode.No Then
		ClosingInProgress = True;
		Modified = False;
		Close();
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndCloseExecute()
	
	RecordRangeOfAcceptablePrices();
	Close();
	
EndProcedure

&AtClient
Procedure WriteExecute()
	
	RecordRangeOfAcceptablePrices();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure RecordRangeOfAcceptablePrices()
	
	Query = New Query(
		"SELECT
		|	Constants.KindOfMaximumAllowablePurchasePrice AS KindOfMaximumAllowablePurchasePrice,
		|	Constants.KindOfMaximumAllowableSellingPrices AS KindOfMaximumAllowableSellingPrices,
		|	Constants.KindOfMinimumAllowableSellingPrices  AS KindOfMinimumAllowableSellingPrices
		|FROM
		|	Constants AS Constants
		|");
		
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If KindOfMinimumAllowableSellingPrices <> Selection.KindOfMinimumAllowableSellingPrices Then
			Constants.KindOfMinimumAllowableSellingPrices.Set(KindOfMinimumAllowableSellingPrices);
		EndIf;
			
		If KindOfMaximumAllowableSellingPrices <> Selection.KindOfMaximumAllowableSellingPrices Then
			Constants.KindOfMaximumAllowableSellingPrices.Set(KindOfMaximumAllowableSellingPrices);
		EndIf;
		
		If KindOfMaximumAllowablePurchasePrice <> Selection.KindOfMaximumAllowablePurchasePrice Then
			Constants.KindOfMaximumAllowablePurchasePrice.Set(KindOfMaximumAllowablePurchasePrice);
		EndIf;
			
	EndIf;
	Modified = False;
	
EndProcedure

&AtServer
Procedure ReadAcceptablePriceRange()
	
	Query = New Query(
		"SELECT
		|	Constants.KindOfMaximumAllowablePurchasePrice AS KindOfMaximumAllowablePurchasePrice,
		|	Constants.KindOfMaximumAllowableSellingPrices AS KindOfMaximumAllowableSellingPrices,
		|	Constants.KindOfMinimumAllowableSellingPrices  AS KindOfMinimumAllowableSellingPrices
		|FROM
		|	Constants AS Constants
		|");
		
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		KindOfMinimumAllowableSellingPrices  = Selection.KindOfMinimumAllowableSellingPrices;
		KindOfMaximumAllowableSellingPrices = Selection.KindOfMaximumAllowableSellingPrices;
		KindOfMaximumAllowablePurchasePrice = Selection.KindOfMaximumAllowablePurchasePrice;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
