
#Region Public

// Updates the heading of the Form is subject to excise duty after calculating the number of excisable items in the document.
//
// Parameters:
//  Form - ClientApplicationForm - Customizable Form.
//
Procedure AfterCalculatingNumberOfExcisableItems(Form) Export
	
	If Not Form.UseExcisableGoods Then
		Return;
	EndIf;
	
	UpdateFieldHeaderIsSubjectToExciseDuty(Form);
	
EndProcedure

// Updates the heading of the is subject to excise tax field and, if necessary, connects the waiting handler for checking
// the calculation of the number of excisable items.
//
// Parameters:
//  Form  - ClientApplicationForm - the form being processed.
//
Procedure UpdateFieldHeaderIsSubjectToExciseDuty(Form) Export
	
	If ValueIsFilled(Form.DataForCalculatingNumberOfExcisableGoods) Then
		
		JobID = Form.DataForCalculatingNumberOfExcisableGoods.JobID;
		
		If Form.DataForCalculatingNumberOfExcisableGoods.Status = "Completed2"
			Or (ValueIsFilled(JobID)
				And ExcisableGoodsAccountingServerCall.JobCompleted(JobID)) Then
			
			ResultAddress = Form.DataForCalculatingNumberOfExcisableGoods.ResultAddress;
			Form.Items.SubjectToExcise.Title =
				ExcisableGoodsAccountingServerCall.FieldHeaderIsSubjectToExciseDuty(ResultAddress);
			Form.DataForCalculatingNumberOfExcisableGoods = Undefined;
			Form.ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = False;
			
		Else
			
			Form.Items.SubjectToExcise.Title = NStr("vi = '<đang cập nhật dữ liệu>';
													|ru = '<идет обновление данных>';
													|en = '<data is being updated>'; fa = '<data is being updated>';
													|it = '<aggiornamento dati in corso>';
													|pl = '<trwa aktualizacja danych>';
													|tr = '<veriler güncelleniyor>'");
			Form.AttachIdleHandler("Attachable_UpdateFieldHeaderIsSubjectToExciseDuty", 1, True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
