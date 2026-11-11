#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
// Fills in the initial values of the EMRC for tobacco products.
Procedure FillInValuesOfEMRCRegister() Export
	
	BeginTransaction();
	
	Try
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.ValuesOfUnifiedMinimumRetailPrice");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("AccountingFeature", Enums.MarkedProductsKindsCEL.Tobacco);
		Block.Lock();
		
		RecordSet = InformationRegisters.ValuesOfUnifiedMinimumRetailPrice.CreateRecordSet(); 
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20230101');
		NewRow.Price             = 0.02*3467*(1+0.2)*1.4;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20230301');
		NewRow.Price             = 0.02*3536*(1+0.2)*1.4;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20240101');
		NewRow.Price             = 0.02*3536*(1+0.2)*1.4;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20240301');
		NewRow.Price             = 0.02*3820*(1+0.2)*1.4;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20250101');
		NewRow.Price             = 0.02*3820*(1+0.2)*1.4;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20250301');
		NewRow.Price             = 135;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20260101');
		NewRow.Price             = 135;
		
		NewRow = RecordSet.Add();
		NewRow.AccountingFeature = Enums.MarkedProductsKindsCEL.Tobacco; 
		NewRow.Period           = Date('20260301');
		NewRow.Price             = 153;
		
		RecordSet.Write();
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Lỗi điền các phần tử định trước với giá bán lẻ tối thiểu duy nhất.';
				|ru = 'Ошибка заполнения предопределенных элементов ЕМРЦ.';
				|en = 'An error occurred when filling predefined items of the unified minimum retail price.'; fa = 'An error occurred when filling predefined items of the unified minimum retail price.';
				|it = 'Errore di compilazione degli elementi predefiniti EMRZ.';
				|pl = 'Błąd wypełnienie predefiniowanych elementów jednolitej minimalnej ceny detalicznej.';
				|tr = 'Önceden tanımlanan EMPTZ öğelerinin doldurulması hatası.'", CommonCEL.DefaultLanguageCode()));
		Raise;
		
	EndTry;
	
EndProcedure

// Gets the price of the EMRC from the data of the information database on the date.
//
// Parameters:
//  AccountingFeature - EnumRef.MarkedProductsKindsCEL - the type of labeled products to check the price.
//  Period - Date - date of the price check.
//  EMRC - Number - the value of the EMRC.
//
Procedure GetEMRCPrice(AccountingFeature, Period = Undefined, EMRC = 0) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ValuesOfUnifiedMinimumRetailPriceSliceLast.Price AS Price
	|FROM
	|	InformationRegister.ValuesOfUnifiedMinimumRetailPrice.SliceLast(&Period, AccountingFeature = &AccountingFeature) AS ValuesOfUnifiedMinimumRetailPriceSliceLast";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("AccountingFeature", AccountingFeature);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		EMRC = Selection.Price;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Internal

#Region AllowedMethodsToBeCalledAsArbitraryCode

// Returns a list of methods that can be called as arbitrary code
// (for routine tasks and background tasks)
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("FillInValuesOfEMRCRegister", True);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
