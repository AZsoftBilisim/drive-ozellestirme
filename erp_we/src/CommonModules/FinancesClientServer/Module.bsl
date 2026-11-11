
#Region Public

// The procedure recalculates the amount in the row of the table part "payment Description" when the amount in the document header changes.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject - Current document
//	DocumentAmount - Number - The amount of the document
//	DeleteSingleLine - Boolean - Flag for deleting a line
//
Procedure RecalculateAmountsInPaymentDecryptionLine(Object, DocumentAmount, DeleteSingleLine = True) Export
	
	If DocumentAmount = 0 And (DeleteSingleLine Or Object.ARAPDetails.Count() > 1) Then
		
		Object.ARAPDetails.Clear();
		
	ElsIf Object.ARAPDetails.Count() = 1 Then
		
		DecryptionString = Object.ARAPDetails[0];
		DecryptionString.Sum = DocumentAmount;
		If DecryptionString.ARAPCurrency <> Object.Currency Then
			DecryptionString.AmountARAP = 0;
		Else
			DecryptionString.AmountARAP = DocumentAmount;
		EndIf;
		
	ElsIf Object.ARAPDetails.Count() = 0 And DocumentAmount > 0 Then
		
		DecryptionString = Object.ARAPDetails.Add();
		DecryptionString.Sum = DocumentAmount;
		
	ElsIf Object.ARAPDetails.Total("Sum") <> DocumentAmount Then
		
		AmountOfDifference = Object.ARAPDetails.Total("Sum") - DocumentAmount;
		LineNumber = Object.ARAPDetails.Count() - 1;
		
		While LineNumber >= 0 Do
			
			DecryptionString = Object.ARAPDetails[LineNumber];
			
			If DecryptionString.Sum = AmountOfDifference Then
				
				Object.ARAPDetails.Delete(LineNumber);
				Break;
				
			ElsIf DecryptionString.Sum > AmountOfDifference Then
				
				DecryptionString.Sum = DecryptionString.Sum - AmountOfDifference;
				If DecryptionString.ARAPCurrency = Object.Currency Then
					DecryptionString.AmountARAP = DecryptionString.Sum;
				EndIf;
				Break;
				
			ElsIf DecryptionString.Sum < AmountOfDifference Then
				
				AmountOfDifference = AmountOfDifference - DecryptionString.Sum;
				Object.ARAPDetails.Delete(LineNumber);
				
			EndIf;
			
			LineNumber = LineNumber - 1;
			
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion