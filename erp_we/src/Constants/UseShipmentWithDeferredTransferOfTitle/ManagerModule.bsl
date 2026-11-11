
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks the availability of shipment documents in the information database without transferring ownership of version 2.0.
//
// Returns:
// 	Boolean - a sign of the availability of documents.
//
Function ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentRegistryTable
	|WHERE
	|	DocumentRegistryTable.Posted
	|	AND DocumentRegistryTable.BusinessOperation IN
	|	(VALUE(Enum.BusinessTransactions.AccrualVATFromSalesOfGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ShipmentWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Internal

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Constants.UseShipmentWithDeferredTransferOfTitle.ProcessDataSetConstantsShipmentWithoutPPP";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Seamless";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("4f181f7b-7677-4d57-86b1-d754282af189");
	Handler.ExecuteInMasterNodeOnly = True;
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment =
		NStr("vi = 'Đang điền dấu hiệu sử dụng giao hàng không có chuyển quyền sở hữu';
			|ru = 'Заполняет признак использования отгрузки без перехода права собственности';
			|en = 'Fills the flag that indicates use of shipment without transfer of title to goods'; fa = 'Fills the flag that indicates use of shipment without transfer of title to goods';
			|it = 'Fills the flag that indicates use of shipment without transfer of title to goods';
			|pl = 'Fills the flag that indicates use of shipment without transfer of title to goods';
			|tr = 'Mülkiyet devri olmaksızın sevkiyatların kullanım işaretini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Constants.UseShipmentWithDeferredTransferOfTitle.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.UseShipmentWithDeferredTransferOfTitle2_0.FullName());
	Editable1.Add(Metadata.Constants.UseShipmentWithDeferredTransferOfTitle2_5.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Sets constants with signs of using shipment without transfer of ownership
// 	according to schemes 2.0 and 2.5.
//
Procedure ProcessDataSetConstantsShipmentWithoutPPP() Export
	
	Block = New DataLock;
	Block.Add("Constant.UseShipmentWithDeferredTransferOfTitle");
	Block.Add("Constant.UseShipmentWithDeferredTransferOfTitle2_0");
	Block.Add("Constant.UseShipmentWithDeferredTransferOfTitle2_5");
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		ConstantValue = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle");
		If ConstantValue Then
			
			ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0 =
				ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0();
			
			If ThereAreShipmentDocumentsWithoutTransferOfOwnership2_0
				And Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
				Constants.UseShipmentWithDeferredTransferOfTitle2_0.Set(True);
			EndIf;
			
			If GetFunctionalOption("UseCustomerContracts")
				And Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
				Constants.UseShipmentWithDeferredTransferOfTitle2_5.Set(True);
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Undefined);
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
