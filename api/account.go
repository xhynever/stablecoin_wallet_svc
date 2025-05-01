package api

import (
	"github.com/gin-gonic/gin"
)

type createAccountRequest struct {
	Currency string `json:"currency" binding:"required,currency"`
}

func (server *Server) createWallet(ctx *gin.Context) {

}

// func (server *Server) createAccount(ctx *gin.Context) {
// 	var req createAccountRequest
// 	if err := ctx.ShouldBindJSON(&req); err != nil {
// 		ctx.JSON(http.StatusBadRequest, errorResponse(err))
// 		return
// 	}

// 	authPayload := ctx.MustGet(authorizationPayloadKey).(*token.Payload)
// 	arg := db.CreateAccountParams{
// 		Owner:    authPayload.Username,
// 		Currency: req.Currency,
// 		Balance:  0,
// 	}

// 	account, err := server.store.CreateAccount(ctx, arg)
// 	if err != nil {
// 		errCode := db.ErrorCode(err)
// 		if errCode == db.ForeignKeyViolation || errCode == db.UniqueViolation {
// 			ctx.JSON(http.StatusForbidden, errorResponse(err))
// 			return
// 		}
// 		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
// 		return
// 	}

// 	ctx.JSON(http.StatusOK, account)
// }

type getAccountRequest struct {
	ID int64 `uri:"id" binding:"required,min=1"`
}
