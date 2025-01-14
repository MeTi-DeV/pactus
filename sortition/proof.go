package sortition

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
)

type Proof [48]byte

func ProofFromString(text string) (Proof, error) {
	data, err := hex.DecodeString(text)
	if err != nil {
		return Proof{}, err
	}

	return ProofFromBytes(data)
}

func ProofFromBytes(data []byte) (Proof, error) {
	if len(data) != 48 {
		return Proof{}, fmt.Errorf("invalid proof length")
	}

	p := Proof{}
	copy(p[:], data)

	return p, nil
}

func GenerateRandomProof() Proof {
	p := Proof{}
	_, err := rand.Read(p[:])
	if err != nil {
		panic(err)
	}
	return p
}
