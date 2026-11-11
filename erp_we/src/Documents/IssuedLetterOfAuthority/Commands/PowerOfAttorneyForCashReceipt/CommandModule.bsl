#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("AvailabilityOfDSOrders", True);
	FormParameters.Insert("FormCaption", NStr("vi = 'Giấy ủy quyền thu tiền';
												|ru = 'Доверенности на получение наличных денежных средств';
												|en = 'Authorization letters for cash receipt'; fa = 'Authorization letters for cash receipt';
												|it = 'Deleghe per incasso dei fondi monetari in contanti';
												|pl = 'Pełnomocnictwa na otrzymanie środków pieniężnych gotówki';
												|tr = 'Nakit çekimi için vekaletnameler'"));
	FormNameWorkplacePowerOfAttorney = "Document.IssuedLetterOfAuthority.Form.DocumentsListForm";
	OpenForm(FormNameWorkplacePowerOfAttorney, FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
		
EndProcedure

#EndRegion