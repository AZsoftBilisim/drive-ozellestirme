
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Compliance with the list of details that determine the uniqueness of the key
// 
// Returns:
//   Map - the key is the name of the props 
//
Function KeyAttributes() Export
	
	Result = New Map;
	Result.Insert("ReferenceOrder");
	
	Return Result;
	
EndFunction


// Looking for a registration document by order of the
//
// Parameters:
//  ReferenceOrder - CatalogRef.TermsOfPurchaseFromVendors, CatalogRef.CounterpartyContracts -
// 
// Returns:
//  DocumentRef.VendorContractVendorAgreementRecorder - link to the document.
//
Function RegistrarByOrderOf(ReferenceOrder) Export
	
	If TypeOf(ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors")
			And TypeOf(ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
				Return ReferenceOrder;
	EndIf;
	
	Result = Undefined;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Table.Ref AS Document
	|FROM
	|	Document.VendorContractVendorAgreementRecorder AS Table
	|WHERE
	|	Table.ReferenceOrder = &ReferenceOrder
	|ORDER BY
	|	Document";
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Result = Selection.Document;
		
	Else
		
		ExceptionText = NStr("vi = 'Không tìm thấy chứng từ nguồn ghi của bản ghi kết chuyển trong lịch biểu biến động hàng hóa theo lệnh %ReferenceOrder%.';
							|ru = 'Не найден документ-регистратор движения графика движения товаров по распоряжению %ReferenceOrder%.';
							|en = 'Document recording inventory transfer schedule for the %ReferenceOrder% reference is not found.'; fa = 'Document recording inventory transfer schedule for the %ReferenceOrder% reference is not found.';
							|it = 'Non è stato trovato il documento-registrazione del orario di trasferimento di merci in base alla disposizione %ReferenceOrder%.';
							|pl = 'Nie znaleziono dokumentu rejestratora przepływu harmonogramu przepływu towarów według zamówienia %ReferenceOrder%.';
							|tr = '""%ReferenceOrder%"" siparişi için mal hareket çizelgesinin belge kaydedici hareketi bulunamadı.'");
		ExceptionText = StrReplace(ExceptionText, "%ReferenceOrder%", ReferenceOrder);
		Raise ExceptionText;
		
	EndIf;
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(ReferenceOrder.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#EndRegion

#EndIf
