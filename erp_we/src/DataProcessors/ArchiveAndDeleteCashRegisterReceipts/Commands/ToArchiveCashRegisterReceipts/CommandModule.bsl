
&AtServer
Procedure ArchiveReceiptsOnServer(CashRegisterShift)
	
	Query = New Query(
	"SELECT
	|	CashRegisterShift.Ref AS CashRegisterShift
	|FROM
	|	Document.CashRegisterShift AS CashRegisterShift
	|WHERE
	|	CashRegisterShift.Posted
	|	AND CashRegisterShift.Ref IN (&CashRegisterShift)
	|	AND CashRegisterShift.PeriodEndTransactionsStatus <> VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)
	|");
	
	Query.SetParameter("CashRegisterShift", CashRegisterShift);
	
	CashShiftsProcessed = Query.Execute().Unload().UnloadColumn("CashRegisterShift");
	
	JobParameters = RetailSales.NewParametersForCashierShiftClosingTask();
	JobParameters.CashRegisterShift = CashShiftsProcessed;
	JobParameters.ProcessSucceeded = False;
	
	RetailSales.ExecuteArchiveCashRegisterReceipts(JobParameters);
	
EndProcedure

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ClearMessages();
	
	ArchiveReceiptsOnServer(CommandParameter);
	
	Notify("Write_RetailSalesReport", New Structure, CommandParameter);
	Notify("Write_RetailReturnsReport", New Structure, CommandParameter);
	
	ShowUserNotification(NStr("vi = 'Đã thực hiện lưu trữ phiếu tính tiền';
								|ru = 'Архивация чеков ККМ выполнена';
								|en = 'Receipts have been archived'; fa = 'Receipts have been archived';
								|it = 'L''archiviazione degli scontrini di KKM (Macchinari di Registrazione e Controllo) è stata effettuata';
								|pl = 'Sprawdzanie archiwizacji wykonane KF';
								|tr = 'Kasa fişlerinin arşivlenmesi yapıldı'", CommonClient.DefaultLanguageCode()));
	
EndProcedure
