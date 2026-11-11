#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("AvailabilityOfOrdersGoods", True);
	FormParameters.Insert("FormCaption", NStr("vi = 'Giấy giới thiệu để nhận hàng hóa';
												|ru = 'Доверенности на получение товаров';
												|en = 'Authorization letters for goods receipt'; fa = 'وکالت‌نامه‌های دریافت کالا';
												|it = 'Deleghe per il ritiro merci';
												|pl = 'Pełnomocnictwa do odbioru towarów';
												|tr = 'Malların kabulüne ilişkin vekaletnameler'"));
	FormNameWorkplacePowerOfAttorney = "Document.IssuedLetterOfAuthority.Form.DocumentsListForm";
	OpenForm(FormNameWorkplacePowerOfAttorney, FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
		
EndProcedure

#EndRegion