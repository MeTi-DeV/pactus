package node

import (
	"testing"

	"github.com/pactus-project/pactus/crypto"
	"github.com/pactus-project/pactus/crypto/bls"
	"github.com/pactus-project/pactus/crypto/hash"
	"github.com/pactus-project/pactus/node/config"
	"github.com/pactus-project/pactus/types/account"
	"github.com/pactus-project/pactus/types/genesis"
	"github.com/pactus-project/pactus/types/param"
	"github.com/pactus-project/pactus/types/validator"
	"github.com/pactus-project/pactus/util"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRunningNode(t *testing.T) {
	pub, pv := bls.GenerateTestKeyPair()
	acc := account.NewAccount(crypto.TreasuryAddress, 0)
	acc.AddToBalance(21 * 1e14)
	val := validator.NewValidator(pub, 0)
	gen := genesis.MakeGenesis(util.Now(), []*account.Account{acc}, []*validator.Validator{val}, param.DefaultParams())
	conf := config.DefaultConfig()
	conf.Network.Listens = []string{"/ip4/0.0.0.0/tcp/0"}
	conf.GRPC.Enable = false
	conf.HTTP.Enable = false
	conf.Store.Path = util.TempDirPath()
	conf.Network.NodeKey = util.TempFilePath()

	signer := crypto.NewSigner(pv)
	n, err := NewNode(gen, conf, signer)

	require.NoError(t, err)
	assert.Equal(t, n.state.LastBlockHash(), hash.UndefHash)

	err = n.Start()
	require.NoError(t, err)
	n.Stop()
}
